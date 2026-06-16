{...}: {
  flake.nixosModules.helix = {...}: {
    home-manager.users.grey = {lib, ...}: {
      programs.helix = {
        enable = true;
        settings = {
          theme = lib.mkForce "catppuccin_transparent";
          editor.cursor-shape.normal = "bar";
        };

        themes.catppuccin_transparent = {
          inherits = "catppuccin_mocha";
          "ui.background" = {bg = "none";};
        };
      };
    };
  };
}
