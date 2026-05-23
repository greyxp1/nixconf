{ ... }:
{
  flake.nixosModules.kitty =
    { ... }:
    {
      home-manager.users.grey =
        { ... }:
        {
          programs.kitty = {
            enable = true;

            font = {
              name = "JetBrainsMono Nerd Font";
              size = 13;
            };

            settings = {
              cursor_shape = "beam";
              cursor_blink_interval = 0;
              cursor_trail = 4;
              cursor_trail_decay = "0.1 0.4";
              allow_bold_font_into_color = "no";
              background_opacity = "0.81";
              window_padding_width = 10;
              detect_urls = true;
              tab_bar_style = "powerline";
              tab_powerline_style = "slanted";
              strip_trailing_spaces = "smart";
              confirm_os_window_close = 0;
              enable_audio_bell = "no";
              scrollback_lines = 10000;

              "map ctrl+shift+a" =
                "combine : launch --stdin-source=@screen_scrollback --type=clipboard : "
                + "kitten notify --type=info --icon=edit-copy \"Clipboard\" "
                + "\"Terminal scrollback copied successfully!\"";
            };
          };
        };
    };
}
