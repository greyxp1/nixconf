{
  inputs,
  lib,
  pkgs,
  ...
}: let
  catppuccin = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [../_custom-modules/yazi.nix];
  environment.etc."mime.types".source = "${pkgs.mailcap}/etc/mime.types";
  programs.yazi = {
    enable = true;
    package = pkgs.yazi.override {
      extraPackages = [pkgs.udisks2 (lib.getBin pkgs.util-linux)];
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
    '';
    # The wrapper points YAZI_CONFIG_HOME at the store, so a full theme file can only be added as a flavor.
    flavors.catppuccin-mocha = pkgs.runCommandLocal "catppuccin-mocha.yazi" {} ''
      mkdir $out
      ln -s "${catppuccin.bat}/Catppuccin Mocha.tmTheme" $out/tmtheme.xml
      sed -e '/^overall = /d' \
        -e 's/^\(\s*\){ if = "dir", text = "[^"]*"\(.*\)/\1{ if = "dir \& hovered", text = ""\2\n&/' \
        ${catppuccin.yazi}/mocha/catppuccin-mocha-mauve.toml > $out/flavor.toml
      grep -q 'dir & hovered' $out/flavor.toml
    '';
    settings.theme.flavor = {
      dark = "catppuccin-mocha";
      light = "catppuccin-mocha";
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
      inherit mount full-border keep-preferences smart-enter;
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
}
