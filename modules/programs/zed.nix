{ ... }: {
  flake.nixosModules.zed = { ... }: {
    home-manager.users.grey = { pkgs, ... }: {
      home.packages = with pkgs; [ nixd ];
      programs.zed-editor = {
        enable = true;
        extensions = [
          "html"
          "git-firefly"
          "nix"
          "kdl"
          "toml"
        ];

        userSettings = {
          buffer_font_family = "JetBrainsMono Nerd Font";
          languages.Nix.language_servers = [ "nixd" ];
          session.trust_all_worktrees = true;
          collaboration_panel.button = false;
          window_decorations = "server";
          project_panel.dock = "left";
          git_panel.dock = "left";

          telemetry = {
            diagnostics = false;
            metrics = false;
          };

          agent = {
            sidebar_side = "right";
            dock = "right";
          };

          lsp.nixd.initialization_options.options.nixos.expr =
            "(builtins.getFlake \"path:/home/grey/nixconf\")"
            + ".nixosConfigurations.desktop.options";
        };
      };
    };
  };
}
