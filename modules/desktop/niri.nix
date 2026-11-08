{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../_custom-modules/niri.nix
    inputs.niri-screenshare.nixosModules.default
    inputs.perch.nixosModules.default
  ];
  services = {
    vellum = {
      enable = true;
      package = inputs.vellum.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
    greetd = {
      enable = true;
      settings.default_session = {
        command = "niri-session";
        user = "grey";
      };
    };
    niri-screenshare = {
      enable = true;
      withPicker = false;
      dynamicCast = true;
      dynamicCastAutoSelectMonitor = true;
    };
  };
  environment = {
    sessionVariables.ACCESSIBILITY_ENABLED = "1";
    pathsToLink = ["/share/applications"];
    systemPackages = [
      (pkgs.tesseract.override {enableLanguages = ["eng"];})
      pkgs.wl-clipboard
      pkgs.xwayland-satellite
    ];
  };

  programs = {
    perch.enable = true;
    niri = {
      enable = true;
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri;
      settings = {
        workspaces = {
          browser = {};
          default = {};
        };
        window-rules = [
          {
            matches = [{"app-id" = "^perch$";}];
            open-floating = true;
            focus-ring.off = {};
            geometry-corner-radius = 0;
            border = {
              on = {};
              width = 1;
              active-color = "#cba6f7";
              inactive-color = "#cba6f7";
            };
          }
          {
            excludes = [{"app-id" = "^perch$";}];
            geometry-corner-radius = 16;
            clip-to-geometry = true;
            draw-border-with-background = false;
          }
          {
            matches = [{"app-id" = "^pixel9$";}];
            open-floating = true;
          }
          {
            matches = [{"app-id" = "^dev\\.rockorager\\.monstar$|^sonora$";}];
            background-effect = {
              blur = true;
              xray = false;
            };
          }
          {
            matches = [{"app-id" = "^helium$";}];
            open-on-workspace = "browser";
          }
          {
            matches = [{title = "^discord\\.com is sharing your screen\\.$";}];
            opacity = 0.0;
            open-focused = false;
            focus-ring.off = {};
            border.off = {};
            shadow.off = {};
          }
          {
            matches = [
              {title = "^Discord Popout(:|$)";}
              {title = "^Picture in picture$";}
              {"app-id" = "^chrome-ldgfbffkinooeloadekpmfoklnobpien-Default$";}
            ];
            open-floating = true;
            focus-ring.off = {};
            default-column-width.fixed = 1024;
            default-window-height.fixed = 576;
            default-floating-position = {
              x = 10;
              y = 10;
              relative-to = "top-right";
            };
          }
          {
            matches = [{title = "^filepicker$";}];
            open-floating = true;
            default-column-width.fixed = 1600;
            default-window-height.fixed = 900;
          }
        ];
        layer-rules = [
          {
            matches = [{namespace = "^noctalia-backdrop";}];
            place-within-backdrop = true;
          }
          {
            matches = [{namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|osd)$";}];
            background-effect.xray = false;
          }
        ];

        binds = {
          repeat = false;
          "Mod+Return" = {action = {spawn = ["monstar"];};};
          "Mod+Escape" = {action = {spawn = ["monstar" "-e" "btm"];};};
          "Mod+E" = {action = {spawn = ["monstar" "-e" "fish" "-C" "y"];};};
          "Mod+B" = {action = {spawn = "helium";};};

          "Mod+C" = {action = {spawn = ["noctalia" "msg" "panel-toggle" "control-center"];};};
          "Alt+Space" = {action = {spawn = ["noctalia" "msg" "panel-toggle" "launcher"];};};
          "Mod+V" = {action = {spawn = ["noctalia" "msg" "panel-toggle" "clipboard"];};};
          "Mod+Print" = {action = {spawn = ["noctalia" "msg" "plugin" "noctalia/screen_recorder:service" "all" "replay-save"];};};

          "XF86AudioRaiseVolume" = {action = {spawn = ["noctalia" "msg" "volume-up"];};};
          "XF86AudioLowerVolume" = {action = {spawn = ["noctalia" "msg" "volume-down"];};};
          "XF86AudioMute" = {action = {spawn = ["noctalia" "msg" "media" "toggle"];};};

          "Mod+Q" = {action = {close-window = {};};};
          "Mod+F" = {action = {maximize-window-to-edges = {};};};
          "Mod+Shift+F" = {action = {fullscreen-window = {};};};
          "Mod+T" = {action = {toggle-window-floating = {};};};
          "Mod+R" = {action = {switch-preset-column-width = {};};};
          "Mod+Tab" = {action = {toggle-overview = {};};};

          "Print" = {action = {screenshot = {};};};
          "Shift+Print" = {action = {spawn-sh = "niri msg screenshot --stdout | perch -";};};
          "Ctrl+Print" = {action = {spawn-sh = "niri msg screenshot --stdout | tesseract - - | wl-copy";};};
          "Mod+Shift+C" = {action = {spawn-sh = "niri msg pick-color | wl-copy";};};
          "Mod+A" = {action = {spawn = ["vellum" "toggle"];};};

          "Mod+H" = {action = {focus-column-or-monitor-left = {};};};
          "Mod+L" = {action = {focus-column-or-monitor-right = {};};};
          "Mod+J" = {action = {focus-window-or-workspace-down = {};};};
          "Mod+K" = {action = {focus-window-or-workspace-up = {};};};

          "Mod+Shift+H" = {action = {move-column-left = {};};};
          "Mod+Shift+L" = {action = {move-column-right = {};};};
          "Mod+Shift+J" = {action = {move-window-down = {};};};
          "Mod+Shift+K" = {action = {move-window-up = {};};};

          "Mod+Shift+ctrl+H" = {action = {consume-or-expel-window-left = {};};};
          "Mod+Shift+ctrl+L" = {action = {consume-or-expel-window-right = {};};};
          "Mod+Shift+ctrl+J" = {action = {move-column-to-workspace-down = {};};};
          "Mod+Shift+ctrl+K" = {action = {move-column-to-workspace-up = {};};};

          "Mod+Shift+WheelScrollUp" = {action = {focus-column-or-monitor-left = {};};};
          "Mod+Shift+WheelScrollDown" = {action = {focus-column-or-monitor-right = {};};};
          "Mod+WheelScrollDown" = {action = {focus-window-or-workspace-down = {};};};
          "Mod+WheelScrollUp" = {action = {focus-window-or-workspace-up = {};};};
        };

        screenshot-path = "~/Pictures/Screenshots/%y-%m-%d-%H-%M-%S.png";
        prefer-no-csd = {};
        hotkey-overlay.skip-at-startup = {};
        gestures.hot-corners.off = {};
        cursor.hide-after-inactive-ms = 5000;
        overview.zoom = 0.25;

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
          fill-empty-space = {};
          maximize-single-window-to-edges = {};
          insert-hint.off = {};
          fullscreen-backdrop-color = "transparent";
          focus-ring.active-color = "#cba6f7";
        };

        blur = {
          noise = 0.03;
          saturation = 1.0;
        };

        debug = {
          honor-xdg-activation-with-invalid-serial = {};
          disable-cursor-plane = {};
          emulate-zero-presentation-time = {};
        };
      };
    };
  };
}
