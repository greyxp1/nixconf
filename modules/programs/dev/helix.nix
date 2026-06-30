{
  flake.homeModules.helix = {lib, pkgs, ...}: {
    home.packages = [ pkgs.lazygit ];
    programs.helix = {
      enable = true;
      defaultEditor = true;

      themes.catppuccin_transparent = {
        inherits = "catppuccin_mocha";
        "ui.background" = {bg = "none";};
      };

      settings = {
        theme = lib.mkForce "catppuccin_transparent";

        editor = {
          cursor-shape.normal = "bar";
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
  };
}
