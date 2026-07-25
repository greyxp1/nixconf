{inputs, ...}: {
  flake.homeModules.noctalia = {pkgs, ...}: {
    home.packages = with pkgs; [gpu-screen-recorder];
    imports = [inputs.noctalia.homeModules.default];
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings = {
        desktop_widgets.enabled = false;
        dock.position = "bottom";
        notification.background_opacity = 0.9;
        system.monitor.enabled = false;
        theme.builtin = "Catppuccin";
        location.auto_locate = true;
        wallpaper.enabled = true;
        lockscreen.tint_intensity = 0.0;
        hooks.started = ''
          noctalia msg wallpaper-set "${./assets/wallpaper.jpg}"
          noctalia msg session lock
          (
            systemctl --user start xdg-desktop-portal.service xdg-desktop-portal-gnome.service &&
            noctalia msg plugin noctalia/screen_recorder:service all replay-start
          ) &
        '';

        bar.default = {
          enabled = true;
          auto_hide = true;
          background_opacity = 0.9;
          start = ["recorder"];
          center = ["workspaces"];
          end = ["tray" "notifications"];
          margin_edge = 0;
          margin_ends = 600;
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

        plugin_settings."noctalia/screen_recorder" = {
          audio_source = "both";
          directory = "~/Videos";
          filename_pattern = "%y-%m-%d-%H-%M-%S";
          video_qp = 10;
          video_codec = "av1";
          replay_enabled = true;
          replay_duration = 120;
          replay_filename_pattern = "%y-%m-%d-%H-%M-%S";
          restore_portal = true;
        };

        plugins = {
          auto_update = true;
          enabled = ["noctalia/screen_recorder"];
          source = [
            {
              kind = "git";
              location = "https://github.com/greyxp1/official-plugins";
              name = "official";
            }
            {
              kind = "git";
              location = "https://github.com/noctalia-dev/community-plugins";
              name = "community";
            }
          ];
        };

        shell = {
          avatar_path = ./assets/user.jpg;
          launch_apps_as_systemd_services = true;
          password_style = "random";
          polkit_agent = true;
          settings_show_advanced = true;
          setup_wizard_enabled = false;
          show_location = false;
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
          tray.hidden = ["chrome_status_icon_1::Discord"];
          recorder.type = "noctalia/screen_recorder:recorder";
          workspaces = {
            display = "none";
            hide_when_empty = true;
          };
        };
      };
    };
  };
}
