{...}: {
  flake.nixosModules.helix = {...}: {
    home-manager.users.grey = {lib, ...}: {
      home.sessionVariables.EDITOR = "hx";
      home.sessionVariables.VISUAL = "hx";
      programs.helix = {
        enable = true;
        settings = {theme = lib.mkForce "catppuccin_transparent";};
        themes = {
          catppuccin_transparent = {
            inherits = "catppuccin_mocha";
            "ui.background" = {bg = "none";};
          };
        };
      };
    };
  };
}
