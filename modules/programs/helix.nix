{...}: {
  flake.nixosModules.helix = {...}: {
    environment.variables.EDITOR = "hx";
    environment.variables.VISUAL = "hx";
    programs.nano.enable = false;
    home-manager.users.grey = {
      pkgs,
      lib,
      ...
    }: {
      home.packages = with pkgs; [nixd efm-langserver statix deadnix jq alejandra];
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
          "ui.background" = {bg = "none";};
        };

        languages = {
          language-server.efm.command = "efm-langserver";
          language = [
            {
              name = "nix";
              auto-format = true;
              formatter.command = "/home/grey/.local/bin/nix-format";
              language-servers = [
                {
                  name = "efm";
                  only-features = ["diagnostics"];
                }
                "nixd"
              ];
            }
          ];
        };
      };

      home.file.".local/bin/nix-format" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          f=$(mktemp --suffix=.nix)
          cat > "$f"
          deadnix --edit -q "$f" >/dev/null 2>&1
          statix fix "$f" >/dev/null 2>&1
          alejandra --quiet "$f" >/dev/null 2>&1
          cat "$f"
          rm -f "$f"
        '';
      };

      xdg.configFile."efm-langserver/config.yaml".text = ''
        version: 2
        log-level: 3
        log-file: /home/grey/.cache/efm-langserver.log

        x-lint-defaults: &lint-defaults
          lint-ignore-exit-code: true
          lint-on-save: true
          lint-after-open: true

        languages:
          nix:
            - <<: *lint-defaults
              lint-command: 'statix check ''${INPUT} -o errfmt'
              lint-formats: ['%f>%l:%c:%t:%n:%m']
              lint-source: statix

            - <<: *lint-defaults
              lint-command: >-
                deadnix --output-format json ''${INPUT} |
                jq -r '.file as $f | .results[]? | "\($f):\(.line // 1):\(.column // 1): \(.message)"'
              lint-formats: ['%f:%l:%c: %m']
              lint-source: deadnix
      '';
    };
  };
}
