{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  source = inputs.lintel;
  shell = lib.getExe config.services.lintel.package;
  fuzzel = lib.getExe pkgs.fuzzel;
in {
  imports = [(source + "/nix/module.nix")];

  config = lib.mkMerge [
    {services.lintel.enable = lib.mkDefault true;}
    (lib.mkIf config.services.lintel.enable {
    services.lintel.package = pkgs.callPackage (source + "/nix/shell.nix") {};

    programs.niri.settings = {
      layer-rules = [
        {
          matches = [{namespace = "^(top-bar|desktop-notification)$";}];
          background-effect = {
            blur = true;
            xray = false;
          };
        }
      ];
      binds = {
        "Mod+C".action.spawn = [shell "toggle-audio"];
        XF86AudioRaiseVolume.action.spawn = lib.mkForce [shell "volume" "up"];
        XF86AudioLowerVolume.action.spawn = lib.mkForce [shell "volume" "down"];
        "Alt+Space".action.spawn = lib.mkForce [shell "toggle-picker" "session-apps" fuzzel "--namespace=session-apps"];
        "Mod+Shift+Escape".action.spawn = lib.mkForce [shell "toggle-picker" "session-apps" fuzzel "--namespace=session-apps" "--search=Session"];
      };
    };

    systemd.user.slices.lintel.description = "Lintel services";
    systemd.user.services =
      lib.genAttrs [
        "desktop-polkit"
        "clipboard-history-text"
        "clipboard-history-image"
        "swaylock"
      ] (_: {serviceConfig.Slice = "lintel.slice";})
      // {
        lintel = {
          environment.LINTEL_LOGIN_BROWSER = lib.getExe config.programs.helium.package;
          environment.LINTEL_OPACITY = toString config.programs.monstar.settings.background-opacity;
          serviceConfig.Slice = "lintel.slice";
        };
      };
    })
  ];
}
