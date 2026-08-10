{
  programs.noctalia.settings.lockscreen_widgets = {
    enabled = true;
    widget = {
      "lockscreen-login-box@DP-2" = {
        box_height = 112.0;
        box_width = 240.0;
        cx = 1280.0;
        cy = 768.0;
        output = "DP-2";
        type = "login_box";
        settings = {
          layout = "compact";
          background_opacity = 0;
          input_radius = 15.0;
          center_password_text = true;
          show_caps_lock = false;
          show_keyboard_layout = false;
          show_login_button = false;
          show_unlock_hint = false;
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
}
