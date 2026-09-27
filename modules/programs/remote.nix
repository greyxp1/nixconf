{inputs, lib, ...}: let
  sunshine = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux.sunshine.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./sunshine-keyboard.patch];
  });
in {
  flake.nixosModules.remote = {username, ...}: {
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
  };

  flake.homeModules.remote = {
    nixconfSystem,
    pkgs,
    ...
  }: {
    home.packages = [pkgs.moonlight-qt] ++ lib.optionals (nixconfSystem != null) [sunshine];

    xdg.configFile = lib.mkIf (nixconfSystem != null) {
      "systemd/user/app-dev.lizardbyte.app.Sunshine.service".source =
        "${sunshine}/share/systemd/user/app-dev.lizardbyte.app.Sunshine.service";
      "systemd/user/graphical-session.target.wants/app-dev.lizardbyte.app.Sunshine.service".source =
        "${sunshine}/share/systemd/user/app-dev.lizardbyte.app.Sunshine.service";
      "systemd/user/app-dev.lizardbyte.app.Sunshine.service.d/codec.conf".text = ''
        [Service]
        ExecStart=
        ExecStart=${lib.getExe sunshine} hevc_mode=1
      '';
    };
  };
}
