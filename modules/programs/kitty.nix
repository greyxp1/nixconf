{...}: {
  flake.nixosModules.kitty = {...}: {
    home-manager.users.grey = {...}: {
      programs.kitty = {
        enable = true;
        settings = {
          cursor_blink_interval = 0;
          cursor_shape_unfocused = "unchanged";
          cursor_trail = 3;
          cursor_trail_decay = "0.05 0.15";
          cursor_trail_start_threshold = 2;
          background_opacity = "0.81";
          window_padding_width = 8;
          placement_strategy = "center";
          sync_to_monitor = "yes";
          detect_urls = true;
          tab_bar_style = "powerline";
          tab_powerline_style = "slanted";
          strip_trailing_spaces = "smart";
          confirm_os_window_close = 0;
          scrollback_lines = 10000;
          enable_audio_bell = "no";
          "map ctrl+y" =
            "combine : launch "
            + "--stdin-source=@screen_scrollback "
            + "--type=clipboard : launch --type=overlay true";
        };

        font = {
          name = "JetBrainsMono Nerd Font";
          size = 14;
        };
      };
    };
  };
}
