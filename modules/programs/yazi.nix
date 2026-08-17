{inputs, ...}: {
  flake.nixosModules.yazi = {
    pkgs,
    lib,
    ...
  }: {
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-termfilechooser];
      config.niri."org.freedesktop.impl.portal.FileChooser" = lib.mkForce ["termfilechooser"];
    };

    environment.etc."mime.types".source = "${pkgs.mailcap}/etc/mime.types";
    services.udisks2.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel") && action.id.startsWith("org.freedesktop.udisks2.")) {
          return polkit.Result.YES;
        }
      });
    '';
  };

  flake.homeModules.yazi = {
    config,
    pkgs,
    ...
  }: let
    plug = on: run: desc: {
      inherit on desc;
      run = "plugin ${run}";
    };
  in {
    imports = [inputs.nix-yazi-plugins.legacyPackages.x86_64-linux.homeManagerModules.default];
    xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
      [filechooser]
      cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      default_dir=$HOME
      env=TERMCMD=kitty -o background_opacity=0.6 --title=filepicker
    '';

    xdg.configFile."yazi/init.lua".text = ''
      require("keep-preferences"):setup({
        path_preferences = {
          {
            path = "^${config.home.homeDirectory}/Downloads",
            defaults = {
              sort_by = "mtime",
              sort_reverse = true,
            },
          },
          {
            path = "^${config.home.homeDirectory}/Pictures",
            defaults = {
              sort_by = "mtime",
              sort_reverse = true,
            },
          },
          {
            path = "^${config.home.homeDirectory}/Videos",
            defaults = {
              sort_by = "mtime",
              sort_reverse = true,
            },
          },
        },
      })
    '';

    programs.yazi = {
      enable = true;
      settings = {
        mgr = {
          ratio = [1 2 5];
          sort_by = "natural";
        };

        opener = {
          play = [
            {
              run = ''mpv --force-window -- "$@"'';
              orphan = true;
            }
          ];
          open = [
            {
              mime = "image/*";
              run = ''perch "$@"'';
              orphan = true;
            }
          ];
        };
      };

      yaziPlugins = {
        enable = true;
        plugins = {
          starship.enable = true;
          full-border.enable = true;
          jump-to-char.enable = true;
          smart-enter = {
            enable = true;
            open_multi = true;
          };
        };
      };

      plugins = with pkgs.yaziPlugins; {inherit mount toggle-pane compress keep-preferences;};
      keymap.mgr.prepend_keymap = [
        (plug ["C"] "compress" "Compress selected files")
        (plug ["M"] "mount" "Mount manager")
        (plug ["<A-p>"] "toggle-pane min-preview" "Hide/show preview pane")
        (plug ["<A-m>"] "toggle-pane max-preview" "Maximize/restore preview pane")
      ];
    };
  };
}
