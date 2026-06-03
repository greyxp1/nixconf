{...}: {
  flake.nixosModules.zed = {...}: {
    home-manager.users.grey = {pkgs, ...}: {
      home.packages = with pkgs; [nixd alejandra];
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

          languages.Nix = {
            language_servers = ["nixd"];
            formatter.external.command = "alejandra";
            formatter.external.arguments = ["--quiet" "--"];
          };

          lsp.nixd.initialization_options.formatting.command = ["alejandra"];
          lsp.nixd.initialization_options.options.nixos.expr =
            "(builtins.getFlake \"path:/home/grey/nixconf\")"
            + ".nixosConfigurations.desktop.options";
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
