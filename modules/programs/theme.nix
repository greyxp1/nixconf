{
  flake.nixosModules.theme = {
    pkgs,
    lib,
    ...
  }: let
    theme = pkgs.catppuccin-gtk.override {
      accents = ["mauve"];
      variant = "mocha";
    };
    cursor = pkgs.catppuccin-cursors.mochaMauve;
    settings = ''
      [Settings]
      gtk-theme-name=catppuccin-mocha-mauve-standard
      gtk-application-prefer-dark-theme=1
      gtk-cursor-theme-name=catppuccin-mocha-mauve-cursors
      gtk-cursor-theme-size=24
    '';
  in {
    environment.systemPackages = [theme cursor];
    environment.pathsToLink = ["/share/themes" "/share/icons"];
    environment.sessionVariables = {
      XCURSOR_THEME = "catppuccin-mocha-mauve-cursors";
      XCURSOR_SIZE = "24";
    };
    environment.etc."xdg/gtk-3.0/settings.ini".text = settings;
    environment.etc."xdg/gtk-4.0/settings.ini".text = settings;
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "catppuccin-mocha-mauve-standard";
            cursor-theme = "catppuccin-mocha-mauve-cursors";
            cursor-size = lib.gvariant.mkInt32 24;
          };
        }
      ];
    };
  };
}
