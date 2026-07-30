{
  flake.homeModules.niri-rules = {
    wayland.windowManager.niri.settings._children = [
      {
        window-rule = {
          geometry-corner-radius = 16;
          clip-to-geometry = true;
          draw-border-with-background = false;
        };
      }
      {
        window-rule = {
          match._props."app-id" = "^com\\.mitchellh\\.ghostty$";
          background-effect = {
            blur = true;
            xray = true;
          };
        };
      }
      {
        window-rule = {
          match._props = {
            "app-id" = "^com\\.mitchellh\\.ghostty$";
            "is-floating" = true;
          };
          background-effect.xray = false;
        };
      }
      {
        window-rule = {
          match._props."app-id" = "^helium$";
          open-on-workspace = "browser";
        };
      }
      {
        window-rule = {
          match._props."app-id" = "^Minecraft";
          open-fullscreen = true;
          open-on-workspace = "default";
        };
      }
      {
        window-rule = {
          match._props."app-id" = "^discord$";
          open-on-workspace = "chat";
          open-maximized-to-edges = true;
        };
      }
      {
        window-rule = {
          _children = [
            {match._props."app-id" = "^discord$";}
            {match._props.title = "^Picture in picture$";}
            {match._props."app-id" = "^chrome-ldgfbffkinooeloadekpmfoklnobpien-Default$";}
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
        };
      }
      {
        window-rule = {
          match._props.title = "^filepicker$";
          open-floating = true;
          default-column-width.fixed = 1600;
          default-window-height.fixed = 900;
        };
      }
      {
        layer-rule = {
          match._props.namespace = "^noctalia-wallpaper";
          place-within-backdrop = true;
        };
      }
      {
        layer-rule = {
          match._props.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|osd)$";
          background-effect.xray = false;
        };
      }
    ];
  };
}
