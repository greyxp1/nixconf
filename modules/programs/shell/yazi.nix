{...}: {
  flake.nixosModules.yazi = {pkgs, ...}: let
    starshipTheme = fromTOML (builtins.readFile ./starship.toml);
    starshipCfg = (pkgs.formats.toml {}).generate "starship-yazi.toml" (starshipTheme // {character.disabled = true;});
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

    home-manager.users.grey = {...}: {
      xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        default_dir=$HOME
        env=TERMCMD=${pkgs.ghostty}/bin/ghostty --background-opacity=0.6 --class=yazi-filepicker --title=filepicker -e
      '';

      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        extraPackages = with pkgs; [ripdrag trash-cli];
        settings.mgr.ratio = [1 2 5];
        settings.mgr.sort_by = "natural";
        settings.opener.edit = [
          {
            run = ''hx "$@"'';
            block = true;
          }
        ];

        plugins = with pkgs.yaziPlugins; {
          inherit smart-enter jump-to-char full-border mount toggle-pane compress restore starship;
        };

        keymap.mgr.prepend_keymap = [
          (plug ["l"] "smart-enter" "Enter dir or open file")
          (plug ["f"] "jump-to-char" "Jump to filename starting with char")
          (plug ["C"] "compress" "Compress selected files")
          (plug ["u"] "restore" "Restore last deleted file")
          (plug ["M"] "mount" "Mount manager")
          (plug ["<A-p>"] "toggle-pane min-preview" "Hide/show preview pane")
          (plug ["<A-m>"] "toggle-pane max-preview" "Maximize/restore preview pane")
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
