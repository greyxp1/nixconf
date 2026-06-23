_: {
  flake.nixosModules.helix = _: {
    environment.variables.EDITOR = "hx";
    environment.variables.VISUAL = "hx";
    programs.nano.enable = false;
    home-manager.users.grey = {lib, ...}: {
      programs.helix = {
        enable = true;
        settings = {
          theme = lib.mkForce "catppuccin_transparent";
          editor = {
            cursor-shape.normal = "bar";
            auto-format = true;
          };
        };

        themes.catppuccin_transparent = {
          inherits = "catppuccin_mocha";
          "ui.background" = {
            bg = "none";
          };
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
  };
}
