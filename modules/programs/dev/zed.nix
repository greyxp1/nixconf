_: {
  flake.homeModules.zed = _: {
    catppuccin.zed.enable = false;
    programs.zed-editor = {
      enable = true;
      userSettings = {
        theme = "Catppuccin Mocha (Blur)";
        icon_theme = "Catppuccin Mocha";
        buffer_font_family = "JetBrainsMono Nerd Font";
        session.trust_all_worktrees = true;
        collaboration_panel.button = false;
        window_decorations = "server";
        project_panel.dock = "left";
        git_panel.dock = "left";
        colorize_brackets = true;

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

        languages.Nix = {
          formatter.external.command = "nix-format";
          language_servers = ["nixd" "!nil"];
        };

        language_models.openai_compatible.FreeLLMAPI = {
          api_url = "http://192.168.1.66:3001/v1";
          available_models = [
            {
              name = "auto";
              max_tokens = 200000;
              max_output_tokens = 32000;
              max_completion_tokens = 200000;
              capabilities = {
                tools = true;
                images = false;
                parallel_tool_calls = false;
                prompt_cache_key = false;
                chat_completions = true;
                interleaved_reasoning = false;
              };
            }
          ];
        };
      };

      extensions = [
        "catppuccin-icons"
        "catppuccin-blur"
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
}
