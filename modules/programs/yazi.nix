{inputs, ...}: {
  flake.nixosModules.yazi = {
    config,
    pkgs,
    lib,
    ...
  }: {
    imports = [inputs.self.wrappers.yazi.install inputs.self.wrappers.termfilechooser.install];
    wrappers.yazi = {
      enable = true;
    };
    xdg.portal = {
      enable = true;
      extraPortals = [config.wrappers.termfilechooser.wrapper];
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

  flake.wrappers.termfilechooser = {pkgs, ...}: {
    imports = ["${inputs.wrapper-xdg-desktop-portal-termfilechooser}/wrapperModules/x/xdg-desktop-portal-termfilechooser/module.nix"];
    settings.filechooser = {
      cmd = "${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh";
      default_dir = "$HOME";
      env = "TERMCMD=monstar -o background-opacity=0.6 --title=filepicker -e";
    };
  };

  flake.wrappers.yazi = {
    lib,
    pkgs,
    ...
  }: let
    plug = on: run: desc: {
      inherit on desc;
      run = "plugin ${run}";
    };
    catppuccin = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system};
    theme = lib.importTOML "${catppuccin.yazi}/mocha/catppuccin-mocha-mauve.toml";
  in {
    imports = ["${inputs.wrapper-yazi}/wrapperModules/y/yazi/module.nix"];
    config = {
      runtimePkgs = [pkgs.starship pkgs.udisks2 (lib.getBin pkgs.util-linux)];
      env.STARSHIP_CONFIG = pkgs.writeText "yazi-starship.toml" (builtins.readFile ./starship/starship.toml);
      settings.theme =
        theme
        // {
          app = builtins.removeAttrs theme.app ["overall"];
          mgr =
            theme.mgr
            // {
              syntect_theme = "${catppuccin.bat}/Catppuccin Mocha.tmTheme";
            };
          icon =
            theme.icon
            // {
              conds = lib.concatMap (icon:
                lib.optional ((icon."if" or "") == "dir") (icon
                  // {
                    "if" = "dir & hovered";
                    text = "";
                  })
                ++ [icon])
              theme.icon.conds;
            };
        };
      settings.yazi = {
        mgr = {
          ratio = [0 3 5];
          sort_by = "natural";
        };

        opener = {
          browser = [
            {
              run = "helium %s";
              orphan = true;
            }
          ];
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
        open.prepend_rules = [
          {
            mime = "application/pdf";
            use = "browser";
          }
        ];
      };

      plugins = with pkgs.yaziPlugins; {
        compress = inputs.compress-yazi;
        inherit mount;
        full-border = {
          package = full-border;
          setup = true;
        };
        keep-preferences = {
          package = keep-preferences;
          setup = true;
          settings.path_preferences = map (directory: {
            path = "^/home/grey/${directory}";
            defaults = {
              sort_by = "mtime";
              sort_reverse = true;
            };
          }) ["Downloads" "Pictures" "Videos"];
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
      settings.keymap.mgr.prepend_keymap = [
        (plug ["l"] "smart-enter" "Enter the child directory, or open the file")
        (plug ["C"] "compress" "Compress selected files")
        (plug ["M"] "mount" "Mount manager")
      ];
    };
  };
}
