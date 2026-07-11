{inputs, ...}: let bind = action: {_props.repeat = false;} // action; in {
  flake.nixosModules.niri = {pkgs, ...}: {
    imports = [inputs.niri-nix.nixosModules.default];
    nixpkgs.overlays = [inputs.niri-nix.overlays.niri-nix];
    environment.variables.UWSM_SILENT_START = 2;

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "uwsm start niri-uwsm.desktop";
        user = "grey";
      };
    };

    programs.niri = {
      enable = true;
      package = pkgs.niri-unstable;
      withUWSM = true;
    };
  };

  flake.homeModules.niri = {pkgs, ...}: {
    imports = [inputs.niri-nix.homeModules.default];
    home.packages = [pkgs.xwayland-satellite];
    wayland.windowManager.niri = {
      enable = true;
      settings = {
        spawn-at-startup = map (cmd: {_args = [cmd];}) ["discord" "steam -silent"];
        workspace = map (ws: {_args = [ws];}) ["browser" "default" "chat" "stage"];
        screenshot-path = "~/Pictures/Screenshots/%y-%m-%d-%H-%M-%S.png";
        prefer-no-csd = {};
        debug.honor-xdg-activation-with-invalid-serial = {};
        overview.workspace-shadow.off = {};
        hotkey-overlay.skip-at-startup = {};
        gestures.hot-corners.off = {};
        cursor.hide-after-inactive-ms = 3000;

        blur = {
          noise = 0.03;
          saturation = 1.0;
        };

        input = {
          touchpad.natural-scroll = {};
          keyboard = {
            repeat-delay = 250;
            repeat-rate = 50;
            numlock = {};
            xkb.layout = "us";
            xkb.options = "caps:escape";
          };
        };

        recent-windows = {
          highlight = {
            padding = 10;
            corner-radius = 14;
          };

          previews = {
            max-height = 680;
            max-scale = 1;
          };
        };

        layout = {
          insert-hint.off = {};
          background-color = "transparent";
          focus-ring.active-color = "#cba6f7";
        };

        output = [
          {
            _args = ["DP-2"];
            mode = "2560x1440@170.071";
          }
        ];

        binds = {
          "Mod+Return" = bind {spawn = "ghostty";};
          "Mod+E" = bind {spawn-sh = "ghostty -e fish -c 'y; fish'";};
          "Mod+B" = bind {spawn = "helium";};
          "Mod+D" = bind {spawn = "discord";};

          "Mod+C" = bind {spawn-sh = "noctalia msg panel-toggle control-center";};
          "Alt+Space" = bind {spawn-sh = "noctalia msg panel-toggle launcher";};
          "Mod+V" = bind {spawn-sh = "noctalia msg panel-toggle clipboard";};
          "Mod+Print" = bind {spawn-sh = "noctalia msg plugin noctalia/screen_recorder:service all replay-save";};

          "XF86AudioRaiseVolume" = bind {spawn-sh = "noctalia msg volume-up";};
          "XF86AudioLowerVolume" = bind {spawn-sh = "noctalia msg volume-down";};
          "XF86AudioMute" = bind {spawn-sh = "noctalia msg media toggle";};

          "Mod+Q" = bind {close-window = {};};
          "Mod+F" = bind {maximize-window-to-edges = {};};
          "Mod+Shift+F" = bind {toggle-window-rule-opacity = {};};
          "Mod+T" = bind {toggle-window-floating = {};};
          "Mod+R" = bind {switch-preset-column-width = {};};
          "Mod+Tab" = bind {toggle-overview = {};};
          "Print" = bind {screenshot = {};};

          "Mod+H" = bind {focus-column-left = {};};
          "Mod+L" = bind {focus-column-right = {};};
          "Mod+J" = bind {focus-window-or-workspace-down = {};};
          "Mod+K" = bind {focus-window-or-workspace-up = {};};

          "Mod+Shift+H" = bind {move-column-left = {};};
          "Mod+Shift+L" = bind {move-column-right = {};};
          "Mod+Shift+J" = bind {move-window-down = {};};
          "Mod+Shift+K" = bind {move-window-up = {};};

          "Mod+Shift+ctrl+H" = bind {consume-or-expel-window-left = {};};
          "Mod+Shift+ctrl+L" = bind {consume-or-expel-window-right = {};};
          "Mod+Shift+ctrl+J" = bind {move-column-to-workspace-down = {};};
          "Mod+Shift+ctrl+K" = bind {move-column-to-workspace-up = {};};

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

            background-effect = {
              blur = true;
              xray = true;
            };
          }
          {
            match._props."is-floating" = true;
            background-effect.xray = false;
          }
          {
            match._props."app-id" = "^helium$";
            open-on-workspace = "browser";
          }
          {
            match._props."app-id" = "^Minecraft";
            open-fullscreen = true;
            open-on-workspace = "default";
          }
          {
            match._props."app-id" = "^discord$";
            open-on-workspace = "chat";
            open-maximized-to-edges = true;
          }
          {
            match = [
              {_props."app-id" = "^discord$";}
              {_props.title = "^Picture in picture$";}
              {_props."app-id" = "^chrome-ldgfbffkinooeloadekpmfoklnobpien-Default$";}
            ];
            exclude._props.title = "(?i).*discord$";
            open-floating = true;
            focus-ring.off = {};
            default-column-width.fixed = 1024;
            default-window-height.fixed = 576;
            default-floating-position._props = {
              x = 10;
              y = 10;
              relative-to = "top-right";
            };
          }
          {
            match._props.title = "^filepicker$";
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
    };
  };
}
