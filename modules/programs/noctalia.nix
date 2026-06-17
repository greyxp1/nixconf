{inputs, ...}: {
  flake.nixosModules.noctalia = {pkgs, ...}: let
    noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    environment.systemPackages = [pkgs.gpu-screen-recorder];
    home-manager.users.grey = {
      imports = [inputs.noctalia.homeModules.default];
      systemd.user.services.noctalia.Service.ExecStartPost = [
        "${pkgs.coreutils}/bin/sleep 5"
        "${noctaliaPkg}/bin/noctalia msg plugin noctalia/screen_recorder:service all replay-start"
      ];
      programs.noctalia = {
        enable = true;
        package = noctaliaPkg;
        systemd.enable = true;
        settings = {
          desktop_widgets.enabled = false;
          dock.position = "bottom";
          notification.background_opacity = 0.81;
          system.monitor.enabled = false;
          theme.builtin = "Catppuccin";
          location.auto_locate = true;
          wallpaper.default.path = ../../assets/wallpapers/wheat.jpg;
          bar.default = {
            auto_hide = true;
            background_opacity = 0.81;
            center = ["workspaces"];
            enabled = true;
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
            start = ["recorder"];
            thickness = 42;
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
            filename_pattern = "%Y%m%d_%H%M%S";
            replay_enabled = true;
            restore_portal = true;
            video_codec = "av1";
          };

          plugins.enabled = ["noctalia/screen_recorder"];
          plugins.source = [
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
              control_center_placement = "centered";
              launcher_categories = false;
              session_placement = "centered";
              transparency_mode = "soft";
            };
          };

          widget = {
            recorder.type = "noctalia/screen_recorder:recorder";
            tray.hidden = ["chrome_status_icon_1"];
            workspaces.display = "none";
          };
        };
      };
    };
  };
}
