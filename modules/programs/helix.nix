{inputs, ...}: {
  flake = {
    wrappers = {
      helix = {
        pkgs,
        wlib,
        ...
      }: let
        nix-format = pkgs.writeShellScriptBin "nix-format" ''
          set -o pipefail
          ${pkgs.statix}/bin/statix fix -s | ${pkgs.alejandra}/bin/alejandra -q
        '';
      in {
        config.install.modules.nixos = {config, ...}: {
          imports = [inputs.self.nixosModules.lazygit];
          wrappers.helix = {
            enable = true;
            languages.language-server.nixd.config.options.nixos.expr =
              "(builtins.getFlake \"path:/home/grey/Projects/nixconf\")"
              + ".nixosConfigurations.${config.networking.hostName}.options";
          };
          environment.variables = {
            EDITOR = "hx";
            VISUAL = "hx";
          };
        };
        imports = [wlib.wrapperModules.helix];
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
              # The browser needs the user config directory, not Helix's wrapper config.
              environment.XDG_CONFIG_HOME = "/home/grey/.config";
            };
            language-server.nixd = {
              command = "nixd";
              config.nixpkgs.expr = "import ${pkgs.path} {}";
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
  };
}
