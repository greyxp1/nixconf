{inputs, ...}: let
  themeFor = pkgs:
    pkgs.catppuccin-gtk.override {
      accents = ["mauve"];
      variant = "mocha";
    };
  settings = ''
    [Settings]
    gtk-theme-name=catppuccin-mocha-mauve-standard
    gtk-application-prefer-dark-theme=1
    gtk-cursor-theme-name=catppuccin-mocha-mauve-cursors
    gtk-cursor-theme-size=24
  '';
in {
  flake.gtkSettings = settings;
  flake.themePackages = pkgs: [(themeFor pkgs) pkgs.catppuccin-cursors.mochaMauve];
  flake.cursorSettings = {
    XCURSOR_THEME = "catppuccin-mocha-mauve-cursors";
    XCURSOR_SIZE = "24";
  };
  flake.nixosModules.theme = {
    pkgs,
    lib,
    ...
  }: {
    environment.systemPackages = inputs.self.themePackages pkgs;
    environment.pathsToLink = ["/share/themes" "/share/icons"];
    environment.sessionVariables = inputs.self.cursorSettings;
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
