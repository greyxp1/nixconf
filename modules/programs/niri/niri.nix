{inputs, ...}: {
  flake.nixosModules.niri = {pkgs, ...}: let
    oniri = pkgs.rustPlatform.buildRustPackage {
      pname = "oniri";
      version = "0-unstable";
      src = inputs.oniri;
      cargoHash = "sha256-50zEsbDP1DlhHr1iAubpDrzLs8FaLOiMuE/k3eE6jQw=";
    };
    bind = action: {_props.repeat = false;} // action;
  in {
    imports = [
      inputs.niri-nix.nixosModules.default
      inputs.niri-autoselect-portal.nixosModules.default
    ];

    nixpkgs.overlays = [inputs.niri-nix.overlays.niri-nix];
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri-unstable;
    services.greetd.enable = true;
    services.greetd.settings.default_session.command = "niri-session";
    services.greetd.settings.default_session.user = "grey";
    services.niri-autoselect-portal.enable = true;
    home-manager.sharedModules = [
      inputs.niri-nix.homeModules.default
      {
        home.packages = with pkgs; [
          xwayland-satellite
          oniri
          inputs.nsticky.packages.${stdenv.hostPlatform.system}.nsticky

          (writeScriptBin "screencast-monitor" ''
            #!${pkgs.dash}/bin/dash
            dbus-monitor --session "type='method_call',interface='org.freedesktop.portal.ScreenCast',member='Start'" \
            | grep --line-buffered "method call" \
            | while read -r _; do niri msg action set-dynamic-cast-monitor; done
          '')

          (writeScriptBin "nsticky-stage-toggle" ''
            #!${pkgs.dash}/bin/dash
            STATE="/tmp/nsticky-staged"
            if [ -f "$STATE" ]; then
              nsticky stage remove-all && rm "$STATE"
            else
              nsticky stage add-all && touch "$STATE"
            fi
          '')
        ];

        xdg.configFile."nsticky/config.toml".text = ''
          [sticky.pip]
          title = "^Picture in picture$"
          [sticky.chrome-pip]
          app_id = "^chrome-ldgfbffkinooeloadekpmfoklnobpien-Default$"
          [sticky.discord-vc]
          app_id = "^discord$"
          title = "^VC[^|]*$"
        '';

        wayland.windowManager.niri.enable = true;
        wayland.windowManager.niri.settings = {
          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png";
          prefer-no-csd = {};
          cursor.hide-after-inactive-ms = 3000;
          cursor.hide-when-typing = {};
          #debug.honor-xdg-activation-with-invalid-serial = {};
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
            gaps = 10;
            focus-ring.active-color = "#cba6f7";
            focus-ring.width = 3;
          };

          spawn-sh-at-startup = [
            {_args = ["oniri --tiling-layout --edges-maximizing"];}
            {_args = ["screencast-monitor"];}
          ];

          spawn-at-startup = map (cmd: {_args = [cmd];}) ["helium" "zeditor" "equibop" "nsticky"];
          workspace = map (ws: {_args = [ws];}) ["browser" "default" "chat" "stage"];
          output = [
            {
              _args = ["DP-2"];
              mode = "2560x1440@170.071";
            }
          ];

          binds = {
            # Apps
            "Mod+Return" = bind {spawn = "ghostty";};
            "Mod+E" = bind {spawn-sh = "ghostty -e yazi";};
            "Mod+B" = bind {spawn = "helium";};
            "Mod+D" = bind {spawn = "equibop";};
            "Mod+Z" = bind {spawn = "zeditor";};

            # Noctalia panels
            "Mod+Escape" = bind {spawn-sh = "noctalia msg panel-toggle session";};
            "Mod+C" = bind {spawn-sh = "noctalia msg panel-toggle control-center";};
            "Mod+S" = bind {spawn-sh = "noctalia msg panel-toggle launcher";};
            "Mod+V" = bind {spawn-sh = "noctalia msg panel-toggle clipboard";};
            "Mod+Print" = bind {spawn-sh = "noctalia msg scripted-widget screen_recorder focused replay-save";};

            # Screencast
            "Mod+Shift+C" = bind {set-dynamic-cast-window = {};};
            "Mod+Ctrl+C" = bind {set-dynamic-cast-monitor = {};};

            # Audio (media keys)
            "XF86AudioRaiseVolume" = bind {spawn-sh = "noctalia msg volume-up";};
            "XF86AudioLowerVolume" = bind {spawn-sh = "noctalia msg volume-down";};
            "XF86AudioMute" = bind {spawn-sh = "noctalia msg media toggle";};

            # Nsticky
            "Mod+G" = bind {spawn-sh = "nsticky sticky toggle-active";};
            "Mod+Shift+G" = bind {spawn-sh = "nsticky-stage-toggle";};

            # Window management
            "Mod+Q" = bind {close-window = {};};
            "Mod+F" = bind {maximize-window-to-edges = {};};
            "Mod+Shift+F" = bind {toggle-window-rule-opacity = {};};
            "Mod+T" = bind {toggle-window-floating = {};};
            "Mod+R" = bind {switch-preset-column-width = {};};
            "Mod+Tab" = bind {toggle-overview = {};};
            "Print" = bind {screenshot = {};};

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
            # Global: rounded, blurred, slightly transparent
            {
              geometry-corner-radius = 16;
              clip-to-geometry = true;
              draw-border-with-background = false;
              opacity = 0.81;
              background-effect.blur = true;
              background-effect.xray = true;
            }
            # Floating windows: no xray bleed-through
            {
              match._props."is-floating" = true;
              background-effect.xray = false;
            }
            # Workspace assignments
            {
              match._props."app-id" = "^helium$";
              open-on-workspace = "browser";
            }
            {
              match._props."app-id" = "^dev.zed.Zed$";
              open-on-workspace = "default";
            }
            {
              match._props."app-id" = "^equibop$";
              open-on-workspace = "chat";
            }
            # Full-opacity exceptions
            {
              match = [
                {_props."app-id" = "^ghostty$|^equibop$|^org.qutebrowser.qutebrowser$";}
                {
                  _props = {
                    app-id = "^helium$";
                    title = "(?i).*(Youtube|Jellyfin-Player).*";
                  };
                }
                {
                  _props = {
                    app-id = "^.virt-manager-wrapped$";
                    title = "(?i).*nixos.*";
                  };
                }
                {_props.title = "^Picture in picture$|^Parsec$";}
              ];
              opacity = 1.0;
            }
            # Sticky / PiP floating windows
            {
              match = [
                {_props."app-id" = "^equibop$";}
                {_props.title = "^Picture in picture$";}
                {_props."app-id" = "^chrome-ldgfbffkinooeloadekpmfoklnobpien-Default$";}
              ];
              exclude._props.title = "Equibop$";
              open-floating = true;
              default-column-width.fixed = 1024; # 768 x 432
              default-window-height.fixed = 576;
              default-floating-position._props = {
                x = 10;
                y = 10;
                relative-to = "top-right";
              };
            }
            # Ghostty filepicker
            {
              match._props = {
                app-id = "^com.mitchellh.ghostty$";
                title = "filepicker";
              };
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
