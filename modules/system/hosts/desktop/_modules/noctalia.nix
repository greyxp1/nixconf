{
  programs.noctalia.settings = {
    shell.session.actions = [
      {
        action = "command";
        command = "systemctl reboot --boot-loader-entry=windows.conf";
        enabled = true;
        glyph = "brand-windows-filled";
        label = "Windows";
      }
    ];

    lockscreen_widgets = {
      enabled = true;
      widget_order = [
        "lockscreen-widget-0000000000000001"
        "lockscreen-login-box@DP-2"
        "lockscreen-widget-0000000000000003"
      ];
      widget = {
        "lockscreen-login-box@DP-2" = {
          box_height = 64.0;
          box_width = 240.0;
          cx = 1280.0;
          cy = 768.0;
          output = "DP-2";
          type = "login_box";
          settings = {
            background_radius = 32.0;
            input_opacity = 1.0;
            input_radius = 32.0;
            show_caps_lock = false;
            show_keyboard_layout = false;
            show_login_button = false;
            show_password_hint = false;
          };
        };

        lockscreen-widget-0000000000000001 = {
          box_height = 192.0;
          box_width = 528.0;
          cx = 1280.0;
          cy = 352.0;
          output = "DP-2";
          type = "clock";
          settings = {
            background = false;
            center_text = true;
          };
        };

        lockscreen-widget-0000000000000003 = {
          cx = 1280.0;
          cy = 1360.0;
          output = "DP-2";
          type = "audio_visualizer";
          settings = {
            background = false;
            show_when_idle = false;
          };
        };
      };
    };
  };
}
