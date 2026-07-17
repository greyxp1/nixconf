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
        notification.background_opacity = 0.81;
        system.monitor.enabled = false;
        theme.builtin = "Catppuccin";
        location.auto_locate = true;

        hooks.started = ''
          noctalia msg session lock
          (
            systemctl --user start xdg-desktop-portal.service xdg-desktop-portal-gnome.service \
              niri-autoselect-portal.service &&
            noctalia msg plugin noctalia/screen_recorder:service all replay-start
          ) &
        '';

        wallpaper = {
          enable = true;
          default.path = ../../assets/wallpapers/wheat.jpg;
        };

        bar.default = {
          enabled = true;
          auto_hide = true;
          background_opacity = 0.81;
          start = ["recorder"];
          center = ["workspaces"];
          end = ["tray" "notifications"];
          margin_edge = 0;
          margin_ends = 550;
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
          quality = "ultra";
          replay_enabled = true;
          replay_duration = 120;
          replay_filename_pattern = "%y-%m-%d-%H-%M-%S";
          restore_portal = true;
          video_codec = "av1";
        };

        plugins = {
          enabled = ["noctalia/screen_recorder"];
          source = [
            {
              auto_update = true;
              kind = "git";
              location = "https://github.com/noctalia-dev/official-plugins";
              name = "official";
            }
            {
              auto_update = true;
              kind = "git";
              location = "https://github.com/noctalia-dev/community-plugins";
              name = "community";
            }
          ];
        };

        shell = {
          avatar_path = "/home/grey/nixconf/assets/user.jpg";
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
            {
              action = "command";
              command = "systemctl reboot --boot-loader-entry=windows.conf";
              enabled = true;
              glyph = "brand-windows-filled";
              label = "Windows";
            }
          ];

          panel = {
            control_center_placement = "floating";
            control_center_position = "center";
            session_placement = "floating";
            session_position = "center";
            transparency_mode = "glass";
          };

          launcher = {
            session_search = true;
            categories = false;
            providers.session.global = true;
          };
        };

        widget = {
          tray.hidden = ["chrome_status_icon_1::Discord"];
          recorder.type = "noctalia/screen_recorder:recorder";
          workspaces.display = "none";
        };

        lockscreen.tint_intensity = 0.0;
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
                background_opacity = 0.9;
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
    };
  };
}
