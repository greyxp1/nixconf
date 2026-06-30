{
  flake.nixosModules.helix = {
    environment.variables.EDITOR = "hx";
    environment.variables.VISUAL = "hx";
    programs.nano.enable = false;
  };

  flake.homeModules.helix = {lib, ...}: {
    programs.helix = {
      enable = true;
      settings = {
        theme = lib.mkForce "catppuccin_transparent";
        editor = {
          cursor-shape.normal = "bar";
          auto-format = true;
          default-yank-register = "+";
          auto-reload = true;
        };
      };

      themes.catppuccin_transparent = {
        inherits = "catppuccin_mocha";
        "ui.background" = {bg = "none";};
      };

      languages.language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "nix-format";
          language-servers = ["nixd"];
        }
      ];
    };
  };
}
