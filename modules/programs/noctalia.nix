{inputs, ...}: {
  flake.nixosModules.noctalia = {pkgs, ...}: {
    environment.systemPackages = [pkgs.gpu-screen-recorder];
  };

  flake.homeModules.noctalia = {
    imports = [inputs.noctalia.homeModules.default];
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings = {
        hooks.started = "noctalia msg plugin noctalia/screen_recorder:service all replay-start";
        desktop_widgets.enabled = false;
        dock.position = "bottom";
        notification.background_opacity = 0.81;
        system.monitor.enabled = false;
        theme.builtin = "Catppuccin";
        location.auto_locate = true;
        wallpaper.default.path = ../../assets/wallpapers/wheat.jpg;

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

        control_center.shortcuts = [
          {type = "notification";}
          {type = "clipboard";}
          {type = "media";}
          {type = "weather";}
        ];

        keybinds = {
          down = ["Ctrl+j"];
          left = ["Ctrl+h"];
          right = ["Ctrl+l"];
          up = ["Ctrl+k"];
        };

        plugin_settings."noctalia/screen_recorder" = {
          color_range = "full";
          filename_pattern = "%y-%m-%d-%H-%M-%S";
          replay_enabled = true;
          replay_duration = 120;
          replay_filename_pattern = "%y-%m-%d-%H-%M-%S";
          restore_portal = true;
          video_codec = "av1";
          audio_codec = "aac";
        };

        plugins = {
          enabled = ["noctalia/screen_recorder"];
          source = [
            {
              auto_update = true;
              kind = "git";
              location = "https://github.com/noctalia-dev/community-plugins";
              name = "community";
            }
            {
              auto_update = true;
              kind = "git";
              location = "https://github.com/greyxp1/official-plugins";
              name = "official";
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

          panel = {
            control_center_placement = "floating";
            control_center_position = "center";
            session_placement = "floating";
            session_position = "center";
            transparency_mode = "soft";
          };

          launcher = {
            session_search = true;
            categories = false;
          };
        };

        widget = {
          tray.hidden = ["chrome_status_icon_1::Discord"];
          recorder.type = "noctalia/screen_recorder:recorder";
          workspaces.display = "none";
        };
      };
    };
  };
}
