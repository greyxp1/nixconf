{...}: {
  flake.nixosModules.theme = {...}: {
    home-manager.users.grey = {
      pkgs,
      lib,
      ...
    }: {
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
      };

      gtk = {
        enable = true;
        theme = {
          name = "catppuccin-mocha-mauve-standard";
          package = pkgs.catppuccin-gtk.override {
            accents = ["mauve"];
            variant = "mocha";
          };
        };
        iconTheme = lib.mkForce {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
      };
    };
  };
}
