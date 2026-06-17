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
      ];

      programs.helix = {
        enable = true;
        settings = {
          theme = lib.mkForce "catppuccin_transparent";
          editor.cursor-shape.normal = "bar";
        };

        themes.catppuccin_transparent = {
          inherits = "catppuccin_mocha";
          "ui.background" = {bg = "none";};
        };

        # efm-langserver is a generic "linter -> LSP" bridge. We don't
        # configure it via a separate config.yaml; Helix sends the
        # `config` block below to efm as a workspace/didChangeConfiguration
        # notification right after startup, which is exactly the format
        # efm expects.
        languages = {
          language-server.efm = {
            command = "efm-langserver";
            config.languages.nix = [
              {
                # statix exits 1 when it finds something (0 when clean) --
                # lintIgnoreExitCode just stops efm from logging a warning
                # on the clean case, parsing still happens on the nonzero case either way.
                lintCommand = ''statix check ''${INPUT} -o errfmt'';
                lintFormats = ["%f>%l:%c:%t:%n:%m"];
                lintSource = "statix";
                lintIgnoreExitCode = true;
                lintOnSave = true;
                lintAfterOpen = true;
              }
              {
                # deadnix always exits 0, so lintIgnoreExitCode = true here
                # is mandatory, not cosmetic -- without it efm silently
                # discards the output and you never see a diagnostic.
                # deadnix has no single-line/errfmt output, so this pipes
                # its JSON through jq into one parseable line per result.
                lintCommand = ''deadnix --output-format json ''${INPUT} | jq -r '.file as $f | .results[]? | "\($f):\(.line // 1):\(.column // 1): \(.message)"' '';
                lintFormats = ["%f:%l:%c: %m"];
                lintSource = "deadnix";
                lintIgnoreExitCode = true;
                lintOnSave = true;
                lintAfterOpen = true;
              }
            ];
          };

          language = [
            {
              name = "nix";
              # nixd still does completion/hover/goto-def/formatting.
              # efm is restricted to diagnostics only, so it never competes
              # with nixd for those other features.
              language-servers = [
                "nixd"
                {
                  name = "efm";
                  only-features = ["diagnostics"];
                }
              ];
            }
          ];
        };
      };
    };
  };
}
