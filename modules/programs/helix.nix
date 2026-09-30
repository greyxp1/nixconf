{inputs, ...}: {
  flake.nixosModules.helix = {config, ...}: {
    imports = [inputs.self.wrappers.helix.install];
    wrappers.helix = {
      enable = true;
      flakeLocation = config.flake.location;
      nixconfSystem = "nixosConfigurations.${config.networking.hostName}";
    };
    environment.variables = {
      EDITOR = "hx";
      VISUAL = "hx";
    };
  };

  flake.homeModules.helix = {
    catppuccin.helix.enable = false;
    programs.lazygit = {
      enable = true;
      settings.notARepository = "skip";
    };
  };

  flake.wrappers.helix = {
    config,
    lib,
    pkgs,
    wlib,
    ...
  }: let
    configurationExpr =
      if config.nixconfSystem == null
      then null
      else
        "(builtins.getFlake \"path:${config.flakeLocation}\")"
        + ".${config.nixconfSystem}";
    nix-format = pkgs.writeShellScriptBin "nix-format" ''
      set -o pipefail
      ${pkgs.statix}/bin/statix fix -s | ${pkgs.alejandra}/bin/alejandra -q
    '';
  in {
    imports = [wlib.wrapperModules.helix];
    options = {
      flakeLocation = lib.mkOption {
        type = lib.types.str;
        default = "/home/grey/Projects/nixconf";
      };
      nixconfSystem = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
    config = {
      runtimePkgs = [nix-format pkgs.mpls pkgs.nixd pkgs.lazygit];
      themes.catppuccin_transparent = {
        inherits = "catppuccin_mocha";
        "ui.background".bg = "none";
      };

      settings = {
        theme = "catppuccin_transparent";
        editor = {
          true-color = true;
          # Keep the wrapper's Helix config directory out of spawned shell commands.
          shell = ["${pkgs.coreutils}/bin/env" "-u" "XDG_CONFIG_HOME" pkgs.runtimeShell "-c"];
          auto-format = true;
          color-modes = true;
          default-yank-register = "+";
          continue-comments = false;
          cursor-shape = {
            normal = "bar";
            insert = "bar";
            select = "bar";
          };

          soft-wrap = {
            enable = true;
            wrap-indicator = "";
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
}
