{...}: {
  flake.nixosModules.helix = {...}: {
    home-manager.users.grey = {
      pkgs,
      lib,
      ...
    }: {
      home.packages = with pkgs; [
        nixd
        efm-langserver
        statix
        deadnix
        jq
        alejandra
      ];

      home.file = {
        ".local/bin/efm-deadnix-lint" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            deadnix --output-format json "$1" \
              | jq -r '.file as $f
                       | .results[]?
                       | "\($f):\(.line // 1):\(.column // 1): \(.message)"'
          '';
        };

        ".local/bin/nix-format" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            # No `set -e` here on purpose: if any tool below fails, we still
            # want to fall through to `cat "$f"` rather than abort with empty
            # stdout, which Helix would apply as "delete the whole buffer".
            f=$(mktemp --suffix=.nix)
            cat > "$f"
            deadnix --edit -q "$f" >/dev/null 2>&1
            statix fix "$f" >/dev/null 2>&1
            alejandra --quiet "$f" >/dev/null 2>&1
            cat "$f"
            rm -f "$f"
          '';
        };
      };

      xdg.configFile."efm-langserver/config.yaml".text = ''
        version: 2
        log-level: 3
        log-file: /home/grey/.cache/efm-langserver.log

        languages:
          nix:
            - lint-command: 'statix check ''${INPUT} -o errfmt'
              lint-formats:
                - '%f>%l:%c:%t:%n:%m'
              lint-source: statix
              lint-ignore-exit-code: true
              lint-on-save: true
              lint-after-open: true

            - lint-command: '/home/grey/.local/bin/efm-deadnix-lint ''${INPUT}'
              lint-formats:
                - '%f:%l:%c: %m'
              lint-source: deadnix
              lint-ignore-exit-code: true
              lint-on-save: true
              lint-after-open: true
      '';

      programs.helix = {
        enable = true;
        settings = {
          theme = lib.mkForce "catppuccin_transparent";
          editor.cursor-shape.normal = "bar";
          editor.auto-format = true;
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
    };
  };
}
