{inputs, ...}: {
  flake.nixosModules.niri = {username, ...}: {
    nixpkgs.overlays = [inputs.niri.overlays.default];
    environment.pathsToLink = ["/share/applications"];
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "niri-session";
        user = username;
      };
    };
  };

  flake.homeModules.niri = {
    wayland.windowManager.niri = {
      enable = true;
      settings = {
        screenshot-path = "~/Pictures/Screenshots/%y-%m-%d-%H-%M-%S.png";
        prefer-no-csd = {};
        debug.honor-xdg-activation-with-invalid-serial = {};
        overview.workspace-shadow.off = {};
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

        _children = [
          {workspace._args = ["browser"];}
          {workspace._args = ["default"];}
          {workspace._args = ["chat"];}
        ];

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
      };
    };
  };
}
