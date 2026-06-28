{inputs, ...}: {
  flake.homeModules.theme = {pkgs, ...}: {
    imports = [inputs.catppuccin.homeModules.catppuccin];
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    home.pointerCursor = {
      package = pkgs.catppuccin-cursors.mochaMauve;
      name = "catppuccin-mocha-mauve-cursors";
      size = 24;
      gtk.enable = true;
    };

    catppuccin = {
      enable = true;
      autoEnable = true;
      flavor = "mocha";
      accent = "mauve";
      gtk.icon.enable = false;
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
      theme = {
        name = "catppuccin-mocha-mauve-standard";
        package = pkgs.catppuccin-gtk.override {
          accents = ["mauve"];
          variant = "mocha";
        };
      };
    };
  };
}
