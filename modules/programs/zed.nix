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

          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          agent = {
            sidebar_side = "right";
            dock = "right";
          };

          inlay_hints = {
            enabled = true;
            show_other_hints = false;
          };

          colorize_brackets = true;
          languages = {
            Nix.formatter.external.command = "alejandra";
            Nix.formatter.external.arguments = ["--quiet" "--"];
          };

          lsp = {
            nixd = {
              initialization_options.formatting.command = ["alejandra" "--quiet" "--"];
              initialization_options.nixos.expr =
                "(builtins.getFlake \"path:/home/grey/nixconf\")"
                + ".nixosConfigurations.desktop.options";
            };
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
