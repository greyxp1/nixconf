{inputs, ...}: {
  flake.homeModules.theme = {config, pkgs, ...}: let
    inherit (config.catppuccin) accent flavor;
  in {
    imports = [inputs.catppuccin.homeModules.catppuccin];
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    home.pointerCursor = {
      enable = true;
      size = 24;
      gtk.enable = true;
    };

    catppuccin = {
      enable = true;
      autoEnable = true;
      flavor = "mocha";
      accent = "mauve";
      cursors.enable = true;
    };

    gtk = {
      enable = true;
      theme = {
        name = "catppuccin-${flavor}-${accent}-standard";
        package = pkgs.catppuccin-gtk.override {
          accents = [accent];
          variant = flavor;
        };
      };
    };
  };
}
