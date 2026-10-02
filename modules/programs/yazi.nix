{
  config,
  inputs,
  ...
}: {
  flake.nixosModules.yazi = {
    pkgs,
    lib,
    ...
  }: {
    imports = [config.flake.wrappers.yazi.install];
    wrappers.yazi = {
      enable = true;
    };
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

  flake.homeModules.yazi = {pkgs, ...}: {
    catppuccin.yazi.enable = false;
    programs.yazi = {
      enable = true;
      package = null;
    };
    xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
      [filechooser]
      cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      default_dir=$HOME
      env=TERMCMD=kitty -o background_opacity=0.6 --title=filepicker
    '';
  };

  flake.wrappers.yazi = {
    config,
    lib,
    pkgs,
    wlib,
    ...
  }: let
    plug = on: run: desc: {
      inherit on desc;
      run = "plugin ${run}";
    };
    catppuccin = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system};
    theme = lib.importTOML "${catppuccin.yazi}/mocha/catppuccin-mocha-mauve.toml";
  in {
    imports = [wlib.wrapperModules.yazi];
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
        inherit mount full-border keep-preferences smart-enter starship;
      };
      constructFiles = {
        init = {
          relPath = "${config.binName}-config/init.lua";
          content = ''
            require("full-border"):setup()
            require("keep-preferences"):setup(${lib.generators.toLua {} {
              path_preferences = map (directory: {
                path = "^/home/grey/${directory}";
                defaults = {
                  sort_by = "mtime";
                  sort_reverse = true;
                };
              }) ["Downloads" "Pictures" "Videos"];
            }})
            require("smart-enter"):setup({ open_multi = true })
            require("starship"):setup()
          '';
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
