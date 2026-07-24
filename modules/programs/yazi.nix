{inputs, ...}: {
  flake.nixosModules.yazi = {
    pkgs,
    lib,
    ...
  }: {
    xdg.portal = {
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

  flake.homeModules.yazi = {pkgs, ...}: let
    plug = on: run: desc: {
      inherit on desc;
      run = "plugin ${run}";
    };
  in {
    imports = [inputs.nix-yazi-plugins.legacyPackages.x86_64-linux.homeManagerModules.default];
    catppuccin.sources.yazi = "${inputs.catppuccin-yazi}/themes";

    xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
      [filechooser]
      cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      default_dir=$HOME
      env=TERMCMD=${pkgs.ghostty}/bin/ghostty --background-opacity=0.6 --title=filepicker -e
    '';

    xdg.configFile."yazi/init.lua".text = ''
      require("keep-preferences"):setup({
        path_preferences = {
          {
            path = "^/home/grey/Downloads",
            defaults = {
              sort_by = "mtime",
              sort_reverse = true,
            },
          },
          {
            path = "^/home/grey/Pictures",
            defaults = {
              sort_by = "mtime",
              sort_reverse = true,
            },
          },
          {
            path = "^/home/grey/Videos",
            defaults = {
              sort_by = "mtime",
              sort_reverse = true,
            },
          },
        },
      })
    '';

    home.packages = with pkgs; [trash-cli ripdrag];
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
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
              run = ''niri-pin "$@"'';
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

          recycle-bin = {
            enable = true;
            keys.open.on = ["R"];
          };

          smart-enter = {
            enable = true;
            open_multi = true;
          };
        };
      };

      plugins = with pkgs.yaziPlugins; {inherit mount toggle-pane compress drag keep-preferences;};
      keymap.mgr.prepend_keymap = [
        (plug ["C"] "compress" "Compress selected files")
        (plug ["M"] "mount" "Mount manager")
        (plug ["<A-p>"] "toggle-pane min-preview" "Hide/show preview pane")
        (plug ["<A-m>"] "toggle-pane max-preview" "Maximize/restore preview pane")
        (plug ["<A-d>"] "drag" "Drag selected files")

        {
          on = ["s"];
          run = ''shell 'file=$(fd --type f --follow . ~ | fzf --preview "bat --color=always {}") && [ -n "$file" ] && ya emit reveal "$file"' --block'';
          desc = "Global file search (Excluding hidden)";
        }

        {
          on = ["S"];
          run = ''shell 'res=$(rg --column --line-number --no-heading --color=always --smart-case "" ~ 2>/dev/null | fzf --ansi --delimiter : --preview "bat --color=always --highlight-line {2} {1}") && [ -n "$res" ] && ya emit reveal "$(echo "$res" | cut -d: -f1)"' --block'';
          desc = "Global content search (Excluding hidden)";
        }
      ];
    };
  };
}
