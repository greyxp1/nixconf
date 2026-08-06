{
  flake.homeModules.helix = {
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    configurationExpr =
      "(builtins.getFlake \"path:${osConfig.programs.nh.flake}\")"
      + ".nixosConfigurations.${osConfig.networking.hostName}";
    nix-format = pkgs.writeShellScript "nix-format" ''
      set -o pipefail
      ${pkgs.statix}/bin/statix fix -s | ${pkgs.alejandra}/bin/alejandra -q
    '';
  in {
    programs = {
      lazygit = {
        enable = true;
        settings.notARepository = "skip";
      };

      helix = {
        enable = true;
        defaultEditor = true;
        themes.catppuccin_transparent = {
          inherits = "catppuccin_mocha";
          "ui.background".bg = "none";
        };

        settings = {
          theme = lib.mkForce "catppuccin_transparent";
          editor = {
            auto-format = true;
            default-yank-register = "+";
            continue-comments = false;
            cursor-shape = {
              normal = "bar";
              insert = "bar";
              select = "bar";
            };
          };

          keys.normal."C-g" = [
            ":new"
            ":insert-output lazygit"
            ":buffer-close!"
            ":redraw"
          ];
        };

        languages = {
          language-server.nixd = {
            command = "${pkgs.nixd}/bin/nixd";
            config = {
              nixpkgs.expr = "import ${pkgs.path} {}";
              options.nixos.expr = "${configurationExpr}.options";
              options.home-manager.expr = "${configurationExpr}.options.home-manager.users.type.getSubOptions []";
            };
          };

          language = [
            {
              name = "nix";
              auto-format = true;
              formatter.command = "${nix-format}";
              language-servers = ["nixd"];
            }
          ];
        };
      };
    };
  };
}
