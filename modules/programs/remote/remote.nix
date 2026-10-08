{
  inputs,
  lib,
  ...
}: let
  sunshinePkgs = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux;
  sunshine = sunshinePkgs.sunshine.overrideAttrs (import ./_sunshine.nix {
    inherit lib;
    inherit (inputs) libvirtualhid;
    pkgs = sunshinePkgs;
  });
  displayFor = pkgs:
    pkgs.writeShellApplication {
      name = "sunshine-display";
      runtimeInputs = [pkgs.niri pkgs.jq];
      text = builtins.readFile ./sunshine-display.sh;
    };
in {
  flake.nixosModules.remote = {
    config,
    pkgs,
    utils,
    ...
  }: let
    isDesktop = config.networking.hostName == "desktop";
    cudaSunshine =
      ((import inputs.sunshine-nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }).sunshine.override {cudaSupport = true;}).overrideAttrs (import ./_sunshine.nix {
        inherit lib;
        inherit (inputs) libvirtualhid;
        pkgs = sunshinePkgs;
        cudaSupport = true;
      });
    display = displayFor pkgs;
    prepCommands = builtins.toJSON [
      {
        do = "${lib.getExe display} start";
        undo = "${lib.getExe display} restore";
      }
    ];
  in {
    imports = [inputs.self.remoteClientModule];
    services.tailscale = {
      enable = true;
      useRoutingFeatures = lib.mkIf isDesktop "server";
      extraSetFlags = ["--operator=grey"] ++ lib.optional isDesktop "--advertise-exit-node";
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/tailscale";
        mode = "0700";
      }
    ];

    boot.kernelModules = ["uhid"];
    users.users.grey.extraGroups = ["uinput"];
    services.udev.extraRules = ''
      SUBSYSTEM=="misc", KERNEL=="uhid", MODE="0660", GROUP="uinput", TAG+="seat", TAG+="uaccess", OPTIONS+="static_node=uhid"
    '';

    services.sunshine = {
      enable = true;
      openFirewall = true;
      package = lib.mkDefault (
        if isDesktop
        then cudaSunshine
        else sunshine
      );
    };

    environment.systemPackages = lib.optional isDesktop display;

    systemd.user.services.sunshine.environment = lib.mkIf isDesktop {
      LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    };

    # CLI settings preserve the configuration edited through Sunshine's web UI.
    systemd.user.services.sunshine.serviceConfig.ExecStart =
      lib.mkForce
      (utils.escapeSystemdExecArgs ([
          (lib.getExe config.services.sunshine.package)
          "csrf_allowed_origins=https://${config.networking.hostName}.tail1785c.ts.net:47990"
        ]
        ++ lib.optional isDesktop "global_prep_cmd=${prepCommands}"));
    systemd.user.services.sunshine.serviceConfig.ExecStopPost =
      lib.mkIf isDesktop "-${lib.getExe display} restore";
  };

  flake.remoteClientModule = {
    config,
    pkgs,
    ...
  }: let
    client = pkgs.moonlight-embedded.overrideAttrs (old: {
      src = inputs.moonlight-embedded;
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/sdl.c \
          --replace-fail 'SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC' 'SDL_RENDERER_ACCELERATED'
      '';
    });
    connect = pkgs.writeShellApplication {
      name = "remote-connect";
      runtimeInputs = [client pkgs.niri pkgs.jq];
      text = builtins.readFile ./remote-connect.sh;
    };
    keyDirectory = "/home/grey/.local/share/moonlight";
    stream = address: bitrate: "${lib.getExe connect} ${address} ${toString bitrate} ${keyDirectory}";
  in {
    environment.systemPackages =
      [client]
      ++ lib.mapAttrsToList (name: address:
        pkgs.makeDesktopItem {
          name = "remote-${name}";
          desktopName = "Connect to ${
            if name == "alma"
            then "Alma"
            else "Desktop"
          }";
          comment = "Remote desktop over Tailscale";
          icon = "${pkgs.adwaita-icon-theme-legacy}/share/icons/AdwaitaLegacy/48x48/places/network-workgroup.png";
          exec = stream address 6000;
          terminal = false;
          categories = ["Network" "RemoteAccess"];
          actions =
            {
              pair = {
                name = "Pair";
                exec = "kitty --hold moonlight pair ${address} -keydir ${keyDirectory}";
              };
            }
            // lib.optionalAttrs (name == "desktop") {
              high-quality = {
                name = "Connect (high quality, home network)";
                exec = stream address 20000;
              };
            };
        }) (lib.filterAttrs (name: _: name != (config.networking.hostName or "alma")) {
        alma = "alma.tail1785c.ts.net";
        desktop = "desktop.tail1785c.ts.net";
      });
  };
}
