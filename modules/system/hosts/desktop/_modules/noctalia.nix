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
      widget = {
        "lockscreen-login-box@DP-2" = {
          output = "DP-2";
          type = "login_box";
          settings = {
            background_opacity = 0.5;
            background_radius = 15.0;
            input_opacity = 0.75;
            input_radius = 15.0;
            center_password_text = true;
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
      };
    };
  };
}
