{
  flake.nixosModules.niri = {
    lib,
    username,
    ...
  }: {
    services.gnome.gnome-keyring.enable = lib.mkForce false;
    xdg.portal.config.niri."org.freedesktop.impl.portal.Secret" = lib.mkForce "none";
    environment.pathsToLink = ["/share/applications" "/share/xdg-desktop-portal"];
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "niri-session";
        user = username;
      };
    };

    nixpkgs.overlays = [
      (final: prev: {
        niri = prev.niri.override (prevArgs: {
          libdisplay-info = prevArgs.libdisplay-info.overrideAttrs (finalAttrs: prevAttrs:
            assert prevAttrs.version == "0.4.0"; {
              version = "0.3.0";
              src = final.fetchFromGitLab {
                domain = "gitlab.freedesktop.org";
                owner = "emersion";
                repo = "libdisplay-info";
                rev = finalAttrs.version;
                sha256 = "sha256-nXf2KGovNKvcchlHlzKBkAOeySMJXgxMpbi5z9gLrdc=";
              };
            });
        });
      })
    ];
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
        cursor.hide-after-inactive-ms = 3000;

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
          {spawn-at-startup._args = ["discord"];}
          {workspace._args = ["browser"];}
          {workspace._args = ["default"];}
          {workspace._args = ["chat"];}
          {workspace._args = ["stage"];}
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
