{inputs, ...}: {
  flake.nixosModules.niri = {
    config,
    pkgs,
    ...
  }: let
    tesseract = pkgs.tesseract.override {enableLanguages = ["eng"];};
  in {
    imports = [
      inputs.self.wrappers.niri.install
      inputs.perch.nixosModules.default
      inputs.vellum.nixosModules.default
    ];
    programs.perch.enable = true;
    services.vellum.enable = true;
    wrappers.niri.enable = true;
    programs.niri = {
      enable = true;
      package = config.wrappers.niri.wrapper;
      useNautilus = false;
    };
    nixpkgs.overlays = [inputs.niri.overlays.default];
    environment.pathsToLink = ["/share/applications"];
    environment.systemPackages = [tesseract pkgs.wl-clipboard pkgs.xwayland-satellite];
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "niri-session";
        user = "grey";
      };
    };
  };

  flake.wrappers.niri = {wlib, ...}: let
    bind = action: _: {
      props.repeat = false;
      content = action;
    };
  in {
    imports = [wlib.wrapperModules.niri];
    extraSettings = [
      {workspace = _: {props = "browser";};}
      {workspace = _: {props = "default";};}
    ];
    settings = {
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
          matches = [{"app-id" = "^kitty$";}];
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
            {
              "app-id" = "^helium$";
              title = " - Helium$";
            }
            {title = "^Picture in picture$";}
            {"app-id" = "^chrome-ldgfbffkinooeloadekpmfoklnobpien-Default$";}
          ];
          excludes = [{title = "^• Discord.* - Helium$";}];
          open-floating = true;
          focus-ring.off = {};
          default-column-width.fixed = 1024;
          default-window-height.fixed = 576;
          default-floating-position = _: {
            props = {
              x = 10;
              y = 10;
              relative-to = "top-right";
            };
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
          matches = [{namespace = "^noctalia-wallpaper";}];
          place-within-backdrop = true;
        }
        {
          matches = [{namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|osd)$";}];
          background-effect.xray = false;
        }
      ];

      binds = {
        "Mod+Return" = bind {spawn = ["kitty"];};
        "Mod+Escape" = bind {spawn = ["kitty" "btm"];};
        "Mod+E" = bind {spawn = ["kitty" "nu" "-e" "y"];};
        "Mod+B" = bind {spawn = "helium";};
        "Mod+D" = bind {spawn = ["helium" "https://discord.com/channels/@me"];};

        "Mod+C" = bind {spawn-sh = "noctalia msg panel-toggle control-center";};
        "Alt+Space" = bind {spawn-sh = "noctalia msg panel-toggle launcher";};
        "Mod+V" = bind {spawn-sh = "noctalia msg panel-toggle clipboard";};
        "Mod+Print" = bind {spawn-sh = "noctalia msg plugin noctalia/screen_recorder:service all replay-save";};

        "XF86AudioRaiseVolume" = bind {spawn-sh = "noctalia msg volume-up";};
        "XF86AudioLowerVolume" = bind {spawn-sh = "noctalia msg volume-down";};
        "XF86AudioMute" = bind {spawn-sh = "noctalia msg media toggle";};

        "Mod+Q" = bind {close-window = {};};
        "Mod+F" = bind {maximize-window-to-edges = {};};
        "Mod+Shift+F" = bind {fullscreen-window = {};};
        "Mod+T" = bind {toggle-window-floating = {};};
        "Mod+R" = bind {switch-preset-column-width = {};};
        "Mod+Tab" = bind {toggle-overview = {};};

        "Print" = bind {screenshot = {};};
        "Shift+Print" = bind {spawn-sh = "niri msg screenshot --stdout | perch -";};
        "Ctrl+Print" = bind {spawn-sh = "niri msg screenshot --stdout | tesseract - - | wl-copy";};
        "Mod+Shift+C" = bind {spawn-sh = "niri msg pick-color | wl-copy";};
        "Mod+A" = bind {spawn-sh = "vellum toggle";};

        "Mod+H" = bind {focus-column-or-monitor-left = {};};
        "Mod+L" = bind {focus-column-or-monitor-right = {};};
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

        "Mod+Shift+WheelScrollUp" = bind {focus-column-or-monitor-left = {};};
        "Mod+Shift+WheelScrollDown" = bind {focus-column-or-monitor-right = {};};
        "Mod+WheelScrollDown" = bind {focus-window-or-workspace-down = {};};
        "Mod+WheelScrollUp" = bind {focus-window-or-workspace-up = {};};

        "Mod+Alt+WheelScrollUp" = bind {set-zoom-level = ["+0.1"];};
        "Mod+Alt+WheelScrollDown" = bind {set-zoom-level = ["-0.1"];};
        "Mod+Alt+Z" = bind {toggle-zoom-lock = {};};
      };
      screenshot-path = "~/Pictures/Screenshots/%y-%m-%d-%H-%M-%S.png";
      prefer-no-csd = {};
      hotkey-overlay.skip-at-startup = {};
      gestures.hot-corners.off = {};
      cursor = {
        hide-after-inactive-ms = 5000;
        scale-with-zoom = {};
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
        fill-empty-space = {};
        maximize-single-window-to-edges = {};
        insert-hint.off = {};
        background-color = "transparent";
        focus-ring.active-color = "#cba6f7";
      };

      blur = {
        noise = 0.03;
        saturation = 1.0;
      };

      overview = {
        workspace-shadow.off = {};
        zoom = 0.25;
      };

      debug = {
        honor-xdg-activation-with-invalid-serial = {};
        disable-cursor-plane = {};
        emulate-zero-presentation-time = {};
      };
    };
  };
}
