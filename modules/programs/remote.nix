{inputs, lib, ...}: let
  sunshine = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux.sunshine.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./sunshine-keyboard.patch];
  });
in {
  flake.nixosModules.remote = {config, username, ...}: {
    boot.kernelModules = ["uhid"];
    users.users.${username}.extraGroups = ["uinput"];
    services.udev.extraRules = ''
      SUBSYSTEM=="misc", KERNEL=="uhid", MODE="0660", GROUP="uinput", TAG+="seat", TAG+="uaccess", OPTIONS+="static_node=uhid"
    '';

    services.sunshine = {
      enable = true;
      openFirewall = true;
      package = lib.mkDefault sunshine;
    };

    # CLI settings preserve the configuration edited through Sunshine's web UI.
    systemd.user.services.sunshine.serviceConfig.ExecStart = lib.mkForce
      "${lib.getExe config.services.sunshine.package} csrf_allowed_origins=https://${config.networking.hostName}.tail1785c.ts.net:47990";
  };

  flake.homeModules.remote = {
    config,
    nixconfSystem,
    osConfig ? {},
    pkgs,
    ...
  }: let
    client = pkgs.moonlight-embedded.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./moonlight-keyboard.patch];
    });
    hostName =
      if nixconfSystem == "systemConfigs.alma"
      then "alma"
      else osConfig.networking.hostName or "";
    hosts = lib.filterAttrs (name: _: name != hostName) {
      alma = "alma.tail1785c.ts.net";
      desktop = "desktop.tail1785c.ts.net";
    };
    keyDirectory = "${config.xdg.dataHome}/moonlight";
  in {
    home.packages = [client] ++ lib.optionals (nixconfSystem != null) [sunshine];

    xdg.desktopEntries = lib.mapAttrs' (name: address:
      lib.nameValuePair "remote-${name}" {
        name = "Connect to ${if name == "alma" then "Alma" else "Desktop"}";
        comment = "Remote desktop over Tailscale";
        icon = "network-workgroup";
        exec = "env SDL_VIDEODRIVER=wayland moonlight stream ${address} -app Desktop -platform sdl -1080 -fps 30 -bitrate 6000 -packetsize 1024 -codec h264 -keydir ${keyDirectory}";
        terminal = false;
        categories = ["Network" "RemoteAccess"];
        actions.pair = {
          name = "Pair";
          exec = "kitty --hold moonlight pair ${address} -keydir ${keyDirectory}";
        };
      })
    hosts;

    xdg.configFile = lib.mkIf (nixconfSystem != null) {
      "systemd/user/app-dev.lizardbyte.app.Sunshine.service".source =
        "${sunshine}/share/systemd/user/app-dev.lizardbyte.app.Sunshine.service";
      "systemd/user/graphical-session.target.wants/app-dev.lizardbyte.app.Sunshine.service".source =
        "${sunshine}/share/systemd/user/app-dev.lizardbyte.app.Sunshine.service";
      "systemd/user/app-dev.lizardbyte.app.Sunshine.service.d/codec.conf".text = ''
        [Service]
        ExecStart=
        ExecStart=${lib.getExe sunshine} hevc_mode=1 csrf_allowed_origins=https://alma.tail1785c.ts.net:47990
      '';
    };
  };
}
