{inputs, ...}: {
  flake.nixosModules.yazi = {pkgs, ...}: let
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
      imports = [inputs.nix-yazi-plugins.legacyPackages.${pkgs.stdenv.hostPlatform.system}.homeManagerModules.default];
      xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        default_dir=$HOME
        env=TERMCMD=${pkgs.kitty}/bin/kitty -o background_opacity=0.6 -o cursor_trail=0 --class=filepicker
      '';

      home.packages = with pkgs; [trash-cli];
      programs.yazi = {
        enable = true;
        package = pkgs.lib.mkForce inputs.yazi.packages.${pkgs.stdenv.hostPlatform.system}.default;
        enableFishIntegration = true;
        settings.mgr.ratio = [1 2 5];
        settings.mgr.sort_by = "natural";
        settings.opener.edit = [
          {
            run = ''hx "$@"'';
            block = true;
          }
        ];

        settings.plugin.prepend_fetchers = pkgs.lib.mkForce [
          {
            url = "*";
            run = "git";
            group = "git";
          }
          {
            url = "*/";
            run = "git";
            group = "git";
          }
        ];

        yaziPlugins.enable = true;
        yaziPlugins.plugins = {
          starship.enable = true;
          full-border.enable = true;
          recycle-bin.enable = true;
          smart-enter.enable = true;
          jump-to-char.enable = true;
          git.enable = true;
          #relative-motions = {
          #  enable = true;
          #  show_numbers = "relative_absolute";
          #  show_motion = true;
          #};
        };

        plugins = with pkgs.yaziPlugins; {inherit mount toggle-pane compress;};
        keymap.mgr.prepend_keymap = [
          (plug ["C"] "compress" "Compress selected files")
          (plug ["M"] "mount" "Mount manager")
          (plug ["<A-p>"] "toggle-pane min-preview" "Hide/show preview pane")
          (plug ["<A-m>"] "toggle-pane max-preview" "Maximize/restore preview pane")
        ];
      };
    };
  };
}
