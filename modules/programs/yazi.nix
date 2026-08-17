{
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
    xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
      [filechooser]
      cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      default_dir=$HOME
      env=TERMCMD=kitty -o background_opacity=0.6 --title=filepicker
    '';

    programs.yazi = {
      enable = true;
      settings = {
        mgr = {
          ratio = [0 3 5];
          sort_by = "natural";
        };

        opener = {
          play = [
            {
              run = "mpv --force-window -- %s";
              orphan = true;
            }
          ];
          open = [
            {
              run = "perch %s";
              orphan = true;
            }
          ];
        };
      };

      plugins = with pkgs.yaziPlugins; {
        inherit compress mount;

        full-border = {
          package = full-border;
          setup = true;
        };
        keep-preferences = {
          package = keep-preferences;
          setup = true;
          settings.path_preferences =
            map (directory: {
              path = "^${config.home.homeDirectory}/${directory}";
              defaults = {
                sort_by = "mtime";
                sort_reverse = true;
              };
            }) [
              "Downloads"
              "Pictures"
              "Videos"
            ];
        };
        smart-enter = {
          package = smart-enter;
          setup = true;
          settings.open_multi = true;
        };
        starship = {
          package = starship;
          setup = true;
        };
      };
      keymap.mgr.prepend_keymap = [
        (plug ["l"] "smart-enter" "Enter the child directory, or open the file")
        (plug ["C"] "compress" "Compress selected files")
        (plug ["M"] "mount" "Mount manager")
      ];
    };
  };
}
