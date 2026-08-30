{
  flake.homeModules.helix = {
    config,
    lib,
    nixconfSystem ? null,
    osConfig,
    pkgs,
    ...
  }: let
    configurationExpr =
      if nixconfSystem != null
      then
        "(builtins.getFlake \"path:${config.flake.location}\")"
        + ".${nixconfSystem}"
      else if osConfig == null
      then null
      else
        "(builtins.getFlake \"path:${config.flake.location}\")"
        + ".nixosConfigurations.${osConfig.networking.hostName}";
    nix-format = pkgs.writeShellScriptBin "nix-format" ''
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
        extraPackages = [nix-format pkgs.mpls pkgs.nixd];
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
          language-server.mpls = {
            command = "mpls";
            args = ["--theme" "catppuccin-mocha"];
          };
          language-server.nixd = {
            command = "nixd";
            config =
              {
                nixpkgs.expr = "import ${pkgs.path} {}";
              }
              // lib.optionalAttrs (configurationExpr != null) {
                options.nixos.expr = "${configurationExpr}.options";
                options.home-manager.expr = "${configurationExpr}.options.home-manager.users.type.getSubOptions []";
              };
          };

          language = [
            {
              name = "markdown";
              language-servers = ["mpls"];
            }
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
  };
}
