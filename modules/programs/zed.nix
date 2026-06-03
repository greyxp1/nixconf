{...}: {
  flake.nixosModules.zed = {...}: {
    home-manager.users.grey = {pkgs, ...}: {
      home.packages = with pkgs; [
        nixd
        nil
        alejandra
        statix
        deadnix
      ];

      xdg.configFile."zed/tasks.json".text = builtins.toJSON [
        {
          label = "statix check";
          command = "statix check $ZED_FILE";
        }
        {
          label = "statix fix";
          command = "statix fix $ZED_FILE";
        }
        {
          label = "deadnix";
          command = "deadnix $ZED_FILE";
        }
        {
          label = "deadnix fix";
          command = "deadnix --edit $ZED_FILE";
        }
      ];

      programs.zed-editor = {
        enable = true;
        userSettings = {
          buffer_font_family = "JetBrainsMono Nerd Font";
          session.trust_all_worktrees = true;
          collaboration_panel.button = false;
          window_decorations = "server";
          project_panel.dock = "left";
          git_panel.dock = "left";
          telemetry.diagnostics = false;
          telemetry.metrics = false;
          agent.sidebar_side = "right";
          agent.dock = "right";
          inlay_hints.enabled = true;
          inlay_hints.show_other_hints = false;
          colorize_brackets = true;
          languages.Nix.formatter.external.command = "alejandra";
          languages.Nix.formatter.external.arguments = ["--quiet" "--"];

          lsp = {
            nixd.initialization_options.formatting.command = ["alejandra" "--quiet" "--"];
            nixd.initialization_options.nixos.expr =
              "(builtins.getFlake \"path:/home/grey/nixconf\")"
              + ".nixosConfigurations.desktop.options";
            nil.initialization_options.formatting.command = ["alejandra" "--quiet" "--"];
          };
        };

        extensions = [
          "html"
          "git-firefly"
          "nix"
          "kdl"
          "toml"
        ];
      };
    };
  };
}
