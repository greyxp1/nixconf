{...}: {
  flake.nixosModules.zed = {...}: {
    programs.nix-ld.enable = true;
    home-manager.users.grey = {pkgs, ...}: {
      home.packages = with pkgs; [nixd nil alejandra];
      programs.zed-editor = {
        enable = true;
        userSettings = {
          #helix_mode = true;
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
          "glsl"
          "ini"
          "lua"
        ];
      };
    };
  };
}
