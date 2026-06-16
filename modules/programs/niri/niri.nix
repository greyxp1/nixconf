{inputs, ...}: {
  flake.nixosModules.niri = {pkgs, ...}: let
    bind = action: {_props.repeat = false;} // action;
  in {
    imports = [inputs.niri-nix.nixosModules.default];
    nixpkgs.overlays = [inputs.niri-nix.overlays.niri-nix];
    services.greetd.enable = true;
    services.greetd.settings.default_session.command = "uwsm start niri-uwsm.desktop";
    services.greetd.settings.default_session.user = "grey";
    environment.variables.UWSM_SILENT_START = "2";
    programs.niri = {
      enable = true;
      package = pkgs.niri-unstable;
      withUWSM = true;
    };

    home-manager.sharedModules = [
      inputs.niri-nix.homeModules.default
      {
        home.packages = [pkgs.xwayland-satellite];
        wayland.windowManager.niri.enable = true;
        wayland.windowManager.niri.settings = {
          spawn-at-startup = map (cmd: {_args = [cmd];}) ["helium" "zeditor" "discord"];
          workspace = map (ws: {_args = [ws];}) ["browser" "default" "chat" "stage"];
          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png";
          prefer-no-csd = {};
          cursor.hide-after-inactive-ms = 3000;
          cursor.hide-when-typing = {};
          debug.honor-xdg-activation-with-invalid-serial = {};
          overview.workspace-shadow.off = {};
          hotkey-overlay.skip-at-startup = {};
          gestures.hot-corners.off = {};
          blur.noise = 0.03;
          blur.saturation = 1.0;

          input.touchpad.natural-scroll = {};
          input.keyboard = {
            repeat-delay = 250;
            repeat-rate = 50;
            numlock = {};
            xkb.layout = "us";
            xkb.options = "caps:escape";
          };

          recent-windows = {
            highlight.padding = 10;
            highlight.corner-radius = 14;
            previews.max-height = 680;
            previews.max-scale = 1;
          };

          layout = {
            insert-hint.off = {};
            background-color = "transparent";
            focus-ring.active-color = "#cba6f7";
            focus-ring.width = 3;
          };

          output = [
            {
              _args = ["DP-2"];
              mode = "2560x1440@170.071";
            }
          ];

          binds = {
            # Apps
            "Mod+Return" = bind {spawn = "kitty";};
            "Mod+E" = bind {spawn-sh = "kitty -o cursor_trail=0 -e yazi";};
            "Mod+B" = bind {spawn = "helium";};
            "Mod+D" = bind {spawn = "discord";};
            "Mod+Z" = bind {spawn = "zeditor";};

            # Noctalia panels
            "Mod+Escape" = bind {spawn-sh = "noctalia msg panel-toggle session";};
            "Mod+C" = bind {spawn-sh = "noctalia msg panel-toggle control-center";};
            "Mod+S" = bind {spawn-sh = "noctalia msg panel-toggle launcher";};
            "Mod+V" = bind {spawn-sh = "noctalia msg panel-toggle clipboard";};
            "Mod+Print" = bind {spawn-sh = "noctalia msg plugin noctalia/screen_recorder:service all replay-save";};

            # Audio (media keys)
            "XF86AudioRaiseVolume" = bind {spawn-sh = "noctalia msg volume-up";};
            "XF86AudioLowerVolume" = bind {spawn-sh = "noctalia msg volume-down";};
            "XF86AudioMute" = bind {spawn-sh = "noctalia msg media toggle";};

            # Window management
            "Mod+Q" = bind {close-window = {};};
            "Mod+F" = bind {maximize-window-to-edges = {};};
            "Mod+Shift+F" = bind {toggle-window-rule-opacity = {};};
            "Mod+T" = bind {toggle-window-floating = {};};
            "Mod+R" = bind {switch-preset-column-width = {};};
            "Mod+Tab" = bind {toggle-overview = {};};
            "Print" = bind {screenshot = {};};

            # Screencast
            "Mod+Shift+C" = bind {set-dynamic-cast-window = {};};
            "Mod+Ctrl+C" = bind {set-dynamic-cast-monitor = {};};

            # Focus movement
            "Mod+H" = bind {focus-column-left = {};};
            "Mod+L" = bind {focus-column-right = {};};
            "Mod+J" = bind {focus-workspace-down = {};};
            "Mod+K" = bind {focus-workspace-up = {};};

            # Window/column movement
            "Mod+Shift+H" = bind {move-column-left = {};};
            "Mod+Shift+L" = bind {move-column-right = {};};
            "Mod+Shift+J" = bind {move-column-to-workspace-down = {};};
            "Mod+Shift+K" = bind {move-column-to-workspace-up = {};};

            # Scroll binds
            "Mod+WheelScrollUp" = bind {focus-workspace-up = {};};
            "Mod+WheelScrollDown" = bind {focus-workspace-down = {};};
            "Mod+Shift+WheelScrollUp" = bind {focus-column-left = {};};
            "Mod+Shift+WheelScrollDown" = bind {focus-column-right = {};};
          };

          window-rule = [
            {
              geometry-corner-radius = 16;
              clip-to-geometry = true;
              draw-border-with-background = false;
              background-effect.blur = true;
              background-effect.xray = true;
            }
            # Floating windows: no xray bleed-through
            {
              match._props."is-floating" = true;
              background-effect.xray = false;
            }
            # Opacity exceptions
            {
              match._props."app-id" = "^steam$|^dev.zed.Zed$";
              opacity = 0.81;
            }
            # Workspace assignments
            {
              match._props."app-id" = "^helium$";
              open-on-workspace = "browser";
            }
            {
              match._props."app-id" = "^dev.zed.Zed$|^steam$";
              open-on-workspace = "default";
            }
            {
              match._props."app-id" = "^steam_app_.*$";
              open-fullscreen = true;
              open-on-workspace = "default";
            }
            {
              match._props."app-id" = "^discord$";
              open-on-workspace = "chat";
            }
            # Sticky / PiP floating windows
            {
              match = [
                {_props."app-id" = "^discord$";}
                {_props.title = "^Picture in picture$";}
                {_props."app-id" = "^chrome-ldgfbffkinooeloadekpmfoklnobpien-Default$";}
              ];
              exclude._props.title = "(?i).*discord$";
              open-floating = true;
              default-column-width.fixed = 1024; # 768 x 432
              default-window-height.fixed = 576;
              default-floating-position._props = {
                x = 10;
                y = 10;
                relative-to = "top-right";
              };
            }
            # filepicker
            {
              match._props = {app-id = "^filepicker$";};
              open-floating = true;
              default-column-width.fixed = 1600;
              default-window-height.fixed = 900;
            }
          ];

          layer-rule = [
            {
              match._props.namespace = "^noctalia-wallpaper";
              place-within-backdrop = true;
            }
            {
              match._props.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|osd)$";
              background-effect.xray = false;
            }
          ];
        };
      }
    ];
  };
}
