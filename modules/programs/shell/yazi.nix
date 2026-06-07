{...}: {
  flake.nixosModules.yazi = {pkgs, ...}: let
    starshipTheme = fromTOML (builtins.readFile ./starship.toml);
    starshipCfg = (pkgs.formats.toml {}).generate "starship-yazi.toml" (starshipTheme
      // {
        format = builtins.replaceStrings ["$character"] [""] starshipTheme.format;
        character.disabled = true;
      });
  in {
    xdg.portal = {
      extraPortals = [pkgs.xdg-desktop-portal-termfilechooser];
      config.niri."org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
    };

    home-manager.sharedModules = [
      {
        xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
          [filechooser]
          cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
          default_dir=$HOME
          env=TERMCMD=${pkgs.ghostty}/bin/ghostty --background-opacity=0.6 --class=yazi-filepicker --title=filepicker -e
        '';
      }
    ];

    home-manager.users.grey = {...}: {
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        shellWrapperName = "yazi";
        extraPackages = with pkgs; [ripdrag trash-cli];
        settings = {
          mgr.ratio = [1 2 5];
          mgr.sort_by = "natural";
          opener.edit = [
            {
              run = ''hx "$@"'';
              block = true;
            }
          ];
        };

        plugins = with pkgs.yaziPlugins; {
          inherit smart-enter jump-to-char full-border mount toggle-pane compress restore starship;
        };

        keymap.mgr.prepend_keymap = [
          {
            on = ["l"];
            run = "plugin smart-enter";
            desc = "Enter dir or open file";
          }
          {
            on = ["f"];
            run = "plugin jump-to-char";
            desc = "Jump to filename starting with char";
          }
          {
            on = ["C"];
            run = "plugin compress";
            desc = "Compress selected files";
          }
          {
            on = ["u"];
            run = "plugin restore";
            desc = "Restore last deleted file";
          }
          {
            on = ["<A-m>"];
            run = "plugin mount";
            desc = "Mount manager";
          }
          {
            on = ["<A-p>"];
            run = "plugin toggle-pane min-preview";
            desc = "Hide/show preview pane";
          }
          {
            on = ["M"];
            run = "plugin toggle-pane max-preview";
            desc = "Maximize/restore preview pane";
          }
          {
            on = ["<A-d>"];
            run = ''shell -- ripdrag --and-exit --target --all "$@" | while read -r fp; do cp -nR "$fp" .; done'';
            desc = "Drag-and-drop (bidirectional)";
          }
        ];

        initLua = ''
          require("full-border"):setup({ type = ui.Border.ROUNDED })
          require("smart-enter"):setup({ open_multi = true })
          require("starship"):setup({ config_file = "${starshipCfg}" })
        '';
      };
    };
  };
}
