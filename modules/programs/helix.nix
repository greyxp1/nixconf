{inputs, ...}: {
  flake.nixosModules.helix = {config, ...}: {
    imports = [inputs.self.wrappers.helix.install inputs.self.wrappers.lazygit.install];
    wrappers.lazygit.enable = true;
    wrappers.helix = {
      enable = true;
      nixconfSystem = "nixosConfigurations.${config.networking.hostName}";
    };
    environment.variables = {
      EDITOR = "hx";
      VISUAL = "hx";
    };
  };

  flake.wrappers.lazygit = {
    pkgs,
    ...
  }: {
    imports = ["${inputs.wrapper-lazygit}/wrapperModules/l/lazygit/module.nix"];
    settings.notARepository = "skip";
    extraConfigFiles = [
      (pkgs.runCommand "catppuccin-lazygit-mocha-mauve.yml" {} ''
        ${pkgs.yq-go}/bin/yq '.gui.theme.authorColors = .gui.authorColors | del(.gui.authorColors)' \
          ${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.lazygit}/mocha/mauve.yml > "$out"
      '')
    ];
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
        "(builtins.getFlake \"path:/home/grey/Projects/nixconf\")"
        + ".${config.nixconfSystem}";
    nix-format = pkgs.writeShellScriptBin "nix-format" ''
      set -o pipefail
      ${pkgs.statix}/bin/statix fix -s | ${pkgs.alejandra}/bin/alejandra -q
    '';
  in {
    imports = [wlib.wrapperModules.helix];
    options = {
      nixconfSystem = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
    config = {
      runtimePkgs = [nix-format pkgs.mpls pkgs.nixd (inputs.self.wrappers.lazygit.wrap {inherit pkgs;})];
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
