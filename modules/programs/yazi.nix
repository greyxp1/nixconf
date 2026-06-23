{inputs, ...}: {
  flake.nixosModules.yazi = {pkgs, ...}: let
    system = pkgs.stdenv.hostPlatform.system;
    plug = on: run: desc: {
      inherit on desc;
      run = "plugin ${run}";
    };
  in {
    xdg.portal = {
      extraPortals = [pkgs.xdg-desktop-portal-termfilechooser];
      config.niri."org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
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

    home-manager.users.grey = {pkgs, lib, ...}: {
      imports = [inputs.nix-yazi-plugins.legacyPackages.${system}.homeManagerModules.default];
      home.activation.catppuccinYaziNoIcons = lib.hm.dag.entryAfter ["writeBoundary"] ''
        theme_file="$HOME/.config/yazi/theme.toml"
        if [ -e "$theme_file" ]; then
          $VERBOSE_ECHO "Stripping catppuccin/yazi icon table from theme.toml..."
          $DRY_RUN_CMD bash -c "sed '/^\[icon\]/,\$d' \"\$(readlink -f "$theme_file")\" > \"$theme_file.tmp\" && mv \"$theme_file.tmp\" \"$theme_file\""
        fi
      '';

      xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        default_dir=$HOME
        env=TERMCMD=${pkgs.kitty}/bin/kitty -o background_opacity=0.6 -o cursor_trail=0 --class=filepicker
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

          opener.play = [
            {
              run = ''mpv --force-window -- "$@"'';
              orphan = true;
              for = "unix";
            }
          ];
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

            #relative-motions = {
            #  enable = true;
            #  show_numbers = "relative_absolute";
            #  show_motion = true;
            #};
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
  };
}
