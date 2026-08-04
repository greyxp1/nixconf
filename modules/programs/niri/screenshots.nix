{inputs, ...}: {
  flake.homeModules.niri-screenshots = {pkgs, ...}: let
    swash = inputs.swash.packages.${pkgs.stdenv.hostPlatform.system}.default;
    tesseract = pkgs.tesseract.override {enableLanguages = ["eng"];};
    capture = command: bind "niri msg screenshot --stdout | ${command}";
    bind = spawn-sh: {
      _props.repeat = false;
      inherit spawn-sh;
    };
  in {
    imports = [inputs.perch.homeModules.default];
    programs.perch.enable = true;
    home.packages = [swash tesseract pkgs.wl-clipboard];
    wayland.windowManager.niri.settings = {
      binds = {
        "Mod+Shift+C" = bind "niri msg pick-color | wl-copy";
        "Shift+Print" = capture "perch -";
        "Alt+Print" = capture "swash";
        "Ctrl+Print" = capture "tesseract stdin stdout | wl-copy";
      };

      _children = [
        {
          window-rule = {
            match._props."app-id" = "^perch$";
            open-floating = true;
            focus-ring.off = {};
            border = {
              on = {};
              active-color = "#cba6f7";
              inactive-color = "#cba6f7";
            };
          };
        }
        {
          window-rule = {
            match._props."app-id" = "^dev\\.lemmy\\.swash$";
            open-floating = true;
          };
        }
      ];
    };
  };
}
