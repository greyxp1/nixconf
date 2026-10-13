{inputs, ...}: {
  flake = {
    nixosModules = {
      yazi = {
        lib,
        pkgs,
        ...
      }: let
        catppuccin = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system};
        theme = lib.importTOML "${catppuccin.yazi}/mocha/catppuccin-mocha-mauve.toml";
      in {
        environment.etc."mime.types".source = "${pkgs.mailcap}/etc/mime.types";
        programs.yazi = {
          enable = true;
          package = pkgs.yazi.override {
            extraPackages = [pkgs.starship pkgs.udisks2 (lib.getBin pkgs.util-linux)];
          };
          initLua = pkgs.writeText "yazi-init.lua" ''
            require("full-border"):setup({})

            local preferences = {}
            for _, directory in ipairs({ "Downloads", "Pictures", "Videos" }) do
              preferences[#preferences + 1] = {
                path = "^/home/grey/" .. directory,
                defaults = { sort_by = "mtime", sort_reverse = true },
              }
            end
            require("keep-preferences"):setup({ path_preferences = preferences })
            require("smart-enter"):setup({ open_multi = true })
            require("starship"):setup({ config_file = "${./starship/starship.toml}" })
          '';
          settings.theme = lib.recursiveUpdate (theme // {app = removeAttrs theme.app ["overall"];}) {
            mgr.syntect_theme = "${catppuccin.bat}/Catppuccin Mocha.tmTheme";
            icon.conds = lib.concatMap (icon:
              lib.optional ((icon."if" or "") == "dir") (icon
                // {
                  "if" = "dir & hovered";
                  text = "";
                })
              ++ [icon])
            theme.icon.conds;
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
          settings.keymap.mgr.prepend_keymap = [
            {
              on = ["l"];
              run = "plugin smart-enter";
              desc = "Enter the child directory, or open the file";
            }
            {
              on = ["C"];
              run = "plugin compress";
              desc = "Compress selected files";
            }
            {
              on = ["M"];
              run = "plugin mount";
              desc = "Mount manager";
            }
          ];
        };
      };
    };

    wrappers.termfilechooser = {pkgs, ...}: {
      install.modules.nixos = {
        config,
        lib,
        ...
      }: {
        xdg.portal = {
          enable = true;
          extraPortals = [config.wrappers.termfilechooser.wrapper];
          config.niri."org.freedesktop.impl.portal.FileChooser" = lib.mkForce ["termfilechooser"];
        };
      };
      imports = ["${inputs.wrapper-xdg-desktop-portal-termfilechooser}/wrapperModules/x/xdg-desktop-portal-termfilechooser/module.nix"];
      settings.filechooser = {
        cmd = "${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh";
        default_dir = "$HOME";
        env = "TERMCMD=monstar -o background-opacity=0.6 --title=filepicker -e";
      };
    };
  };
}
