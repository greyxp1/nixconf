{inputs, lib, ...}: let
  sunshine = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux.sunshine;
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
      package = sunshine;
    };
  };

  flake.homeModules.remote = {
    nixconfSystem,
    pkgs,
    ...
  }: {
    home.packages = [pkgs.moonlight-qt] ++ lib.optionals (nixconfSystem != null) [sunshine];

    xdg.configFile."systemd/user/graphical-session.target.wants/app-dev.lizardbyte.app.Sunshine.service" =
      lib.mkIf (nixconfSystem != null) {
        source = "${sunshine}/share/systemd/user/app-dev.lizardbyte.app.Sunshine.service";
      };
  };
}
