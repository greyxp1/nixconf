{inputs, ...}: {
  flake.homeModules.theme = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.catppuccin) accent flavor;
    catppuccinPackages = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    imports = [inputs.catppuccin.homeModules.catppuccin];
    catppuccin = {
      enable = true;
      autoEnable = true;
      flavor = "mocha";
      accent = "mauve";
      cursors.enable = true;
      sources = lib.mkForce catppuccinPackages;
    };

    home.pointerCursor = {
      enable = true;
      size = 24;
      gtk.enable = true;
    };

    gtk = {
      enable = true;
      colorScheme = "dark";
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
