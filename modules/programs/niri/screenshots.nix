{inputs, ...}: {
  flake.homeModules.niri-screenshots = {pkgs, ...}: let
    tesseract = pkgs.tesseract.override {enableLanguages = ["eng"];};
    capture = command: bind "niri msg screenshot --stdout | ${command}";
    bind = spawn-sh: {
      _props.repeat = false;
      inherit spawn-sh;
    };
  in {
    imports = [
      inputs.vellum.homeModules.default
      inputs.perch.homeModules.default
    ];

    services.vellum.enable = true;
    programs.perch.enable = true;
    home.packages = [tesseract pkgs.wl-clipboard];
    wayland.windowManager.niri.settings = {
      binds = {
        "Mod+Shift+C" = bind "niri msg pick-color | wl-copy";
        "Shift+Print" = capture "perch -";
        "Ctrl+Print" = capture "tesseract - - | wl-copy";
        "Mod+A" = bind "vellum toggle";
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
      ];
    };
  };
}
