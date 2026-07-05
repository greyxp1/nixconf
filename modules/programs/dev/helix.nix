{
  flake.homeModules.helix = {lib, ...}: {
    programs = {
      helix = {
        enable = true;
        defaultEditor = true;

        themes.catppuccin_transparent = {
          inherits = "catppuccin_mocha";
          "ui.background" = {bg = "none";};
        };

        settings = {
          theme = lib.mkForce "catppuccin_transparent";

          editor = {
            auto-format = true;
            default-yank-register = "+";
          };

          keys.normal = {
            "C-g" = [
              ":new"
              ":insert-output lazygit"
              ":buffer-close!"
              ":redraw"
            ];
          };
        };
      };

      lazygit = {
        enable = true;
        settings.notARepository = "skip";
      };
    };
  };
}
