{...}: {
  flake.nixosModules.foot = {...}: {
    home-manager.users.grey = {pkgs, ...}: {
      programs.foot.enable = true;
      programs.foot.settings = {
        scrollback.lines = 10000;
        bell.system = "no";
        "colors-dark".alpha = "0.81";
        "key-bindings" = {"pipe-scrollback" = "[${pkgs.wl-clipboard}/bin/wl-copy] Control+a";};

        main = {
          font = "JetBrainsMono Nerd Font:size=13";
          pad = "10x10";
          "bold-text-in-bright" = "no";
          "box-drawings-uses-font-glyphs" = "yes";
        };

        cursor = {
          blink = "no";
          style = "beam";
          "unfocused-style" = "none";
          "beam-thickness" = "1.5";
        };
      };
    };
  };
}
