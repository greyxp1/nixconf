{
  config,
  lib,
  ...
}: let
  recorderEnabled = builtins.elem "noctalia/screen_recorder" config.programs.noctalia.settings.plugins.enabled;
in {
  imports = [../../_custom-modules/noctalia.nix];
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
  };
  environment.systemPackages = lib.optionals recorderEnabled [config.programs.gpu-screen-recorder.package];
  security.pam.services.noctalia = {};
  programs.noctalia.settings = {
    desktop_widgets.enabled = false;
    notification.background_opacity = 0.9;
    system.monitor.enabled = false;
    theme.builtin = "Catppuccin";
    location.auto_locate = true;
    wallpaper.enabled = false;
    hooks = {
      session_unlocked = ''
        systemctl --user start xdg-desktop-portal.service niri-screenshare.service${lib.optionalString recorderEnabled " && noctalia msg plugin noctalia/screen_recorder:service all replay-start"}
      '';
    };

    bar.default = {
      auto_hide = true;
      background_opacity = 0.9;
      start = lib.optionals recorderEnabled ["recorder"];
      center = ["workspaces"];
      end = ["tray" "notifications"];
      margin_ends = 580;
      position = "right";
      radius_bottom_left = 16;
      radius_bottom_right = 0;
      radius_top_left = 16;
      radius_top_right = 0;
      reserve_space = false;
      scale = 1.4;
      thickness = 42;
      show_on_workspace_switch = false;
    };

    control_center = {
      hidden_tabs = ["monitor" "power" "network" "bluetooth" "screen-time"];
      shortcuts = [
        {type = "notification";}
        {type = "clipboard";}
        {type = "media";}
        {type = "weather";}
      ];
    };

    keybinds = {
      down = ["Ctrl+j"];
      left = ["Ctrl+h"];
      right = ["Ctrl+l"];
      up = ["Ctrl+k"];
    };

    plugin_settings."noctalia/screen_recorder" = lib.mkIf recorderEnabled {
      audio_source = "both";
      directory = "~/Videos";
      filename_pattern = "%y-%m-%d-%H-%M-%S";
      video_bitrate_mode = "qp";
      video_qp = 10;
      video_codec = "av1";
      replay_enabled = true;
      replay_duration = 120;
      replay_filename_pattern = "%y-%m-%d-%H-%M-%S";
      restore_portal = true;
    };

    plugins.enabled = ["noctalia/screen_recorder"];

    shell = {
      avatar_path = ./assets/user.jpg;
      date_format = "%A, %-d/%-m/%y";
      launch_apps_as_systemd_services = true;
      password_style = "random";
      polkit_agent = true;
      setup_wizard_enabled = false;
      show_location = false;
      time_format = "{:%I:%M %p}";
      screen_corners.enabled = true;
      session.actions = [
        {action = "reboot";}
        {action = "shutdown";}
        {action = "lock";}
        {action = "lock_and_suspend";}
        {action = "logout";}
      ];

      panel = {
        control_center_placement = "floating";
        control_center_position = "center";
        session_placement = "floating";
        session_position = "center";
        transparency_mode = "glass";
      };

      launcher = {
        categories = false;
        providers.session.global = true;
      };
    };

    widget = {
      recorder = lib.mkIf recorderEnabled {type = "noctalia/screen_recorder:recorder";};

      tray = {
        drawer = true;
        drawer_item_size = 24.0;
      };

      workspaces = {
        change_color_on_hover = false;
        scroll_repeat = "steps";
        show_labels = false;
      };
    };
  };
}
