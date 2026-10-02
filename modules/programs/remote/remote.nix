{inputs, lib, ...}: let
  sunshine = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux.sunshine.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./sunshine-keyboard.patch];
  });
  displayFor = pkgs: pkgs.writeShellApplication {
    name = "sunshine-display";
    runtimeInputs = [pkgs.niri pkgs.jq];
    text = builtins.readFile ./sunshine-display.sh;
  };
in {
  flake.nixosModules.remote = {config, pkgs, utils, ...}: let
    isDesktop = config.networking.hostName == "desktop";
    cudaSunshine = ((import inputs.sunshine-nixpkgs {
      system = pkgs.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    }).sunshine.override {cudaSupport = true;}).overrideAttrs (old: {
      patches = (old.patches or []) ++ [./sunshine-keyboard.patch];
    });
    display = displayFor pkgs;
    prepCommands = builtins.toJSON [{
      do = "${lib.getExe display} start";
      undo = "${lib.getExe display} restore";
    }];
  in {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = lib.mkIf isDesktop "server";
      extraSetFlags = ["--operator=grey"] ++ lib.optional isDesktop "--advertise-exit-node";
    };

    boot.kernelModules = ["uhid"];
    users.users.grey.extraGroups = ["uinput"];
    services.udev.extraRules = ''
      SUBSYSTEM=="misc", KERNEL=="uhid", MODE="0660", GROUP="uinput", TAG+="seat", TAG+="uaccess", OPTIONS+="static_node=uhid"
    '';

    services.sunshine = {
      enable = true;
      openFirewall = true;
      package = lib.mkDefault (if isDesktop then cudaSunshine else sunshine);
    };

    environment.systemPackages = lib.optional isDesktop display;

    systemd.user.services.sunshine.environment = lib.mkIf isDesktop {
      LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    };

    # CLI settings preserve the configuration edited through Sunshine's web UI.
    systemd.user.services.sunshine.serviceConfig.ExecStart = lib.mkForce
      (utils.escapeSystemdExecArgs ([
        (lib.getExe config.services.sunshine.package)
        "csrf_allowed_origins=https://${config.networking.hostName}.tail1785c.ts.net:47990"
      ] ++ lib.optional isDesktop "global_prep_cmd=${prepCommands}"));
    systemd.user.services.sunshine.serviceConfig.ExecStopPost =
      lib.mkIf isDesktop "-${lib.getExe display} restore";
  };

  flake.homeModules.remote = {
    config,
    nixconfSystem,
    osConfig ? {},
    pkgs,
    ...
  }: let
    display = displayFor pkgs;
    prepCommands = builtins.toJSON [{
      do = "${lib.getExe display} start";
      undo = "${lib.getExe display} restore";
    }];
    # Match the host driver's libc without recompiling the patched Sunshine binary.
    hostSunshine = (pkgs.replaceDirectDependencies {
      drv = sunshine;
      replacements = [{
        oldDependency = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux.glibc;
        newDependency = pkgs.glibc;
      }];
    }) // {inherit (sunshine) meta;};
    client = pkgs.moonlight-embedded.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./moonlight-keyboard.patch];
    });
    connect = pkgs.writeShellApplication {
      name = "remote-connect";
      runtimeInputs = [client pkgs.niri pkgs.jq];
      text = builtins.readFile ./remote-connect.sh;
    };
    hostName =
      if nixconfSystem == "systemConfigs.alma"
      then "alma"
      else osConfig.networking.hostName or "";
    hosts = lib.filterAttrs (name: _: name != hostName) {
      alma = "alma.tail1785c.ts.net";
      desktop = "desktop.tail1785c.ts.net";
    };
    keyDirectory = "${config.xdg.dataHome}/moonlight";
    stream = address: bitrate:
      "${lib.getExe connect} ${address} ${toString bitrate} ${keyDirectory}";
  in {
    home.packages = [client] ++ lib.optionals (nixconfSystem != null) [hostSunshine];

    xdg.desktopEntries = lib.mapAttrs' (name: address:
      lib.nameValuePair "remote-${name}" {
        name = "Connect to ${if name == "alma" then "Alma" else "Desktop"}";
        comment = "Remote desktop over Tailscale";
        icon = "${pkgs.adwaita-icon-theme-legacy}/share/icons/AdwaitaLegacy/48x48/places/network-workgroup.png";
        exec = stream address 6000;
        terminal = false;
        categories = ["Network" "RemoteAccess"];
        actions.pair = {
          name = "Pair";
          exec = "kitty --hold moonlight pair ${address} -keydir ${keyDirectory}";
        };
        actions.high-quality = lib.mkIf (name == "desktop") {
          name = "Connect (high quality, home network)";
          exec = stream address 20000;
        };
      })
    hosts;

    xdg.configFile = lib.mkIf (nixconfSystem != null) {
      "systemd/user/app-dev.lizardbyte.app.Sunshine.service".source =
        "${hostSunshine}/share/systemd/user/app-dev.lizardbyte.app.Sunshine.service";
      "systemd/user/graphical-session.target.wants/app-dev.lizardbyte.app.Sunshine.service".source =
        "${hostSunshine}/share/systemd/user/app-dev.lizardbyte.app.Sunshine.service";
      "systemd/user/app-dev.lizardbyte.app.Sunshine.service.d/codec.conf".text = ''
        [Service]
        ExecStart=
        ExecStart=${lib.getExe hostSunshine} hevc_mode=1 csrf_allowed_origins=https://alma.tail1785c.ts.net:47990 vaapi_quality=balanced qp=20 "global_prep_cmd=${lib.replaceStrings ["\""] ["\\\""] prepCommands}"
        ExecStopPost=-${lib.getExe display} restore
      '';
    };
  };
}
