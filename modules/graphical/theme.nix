{
  pkgs,
  lib,
  ...
}: let
  gtkTheme = "catppuccin-mocha-mauve-standard";
  cursorTheme = "catppuccin-mocha-mauve-cursors";
  cursorSize = 24;
  gtkSettings = ''
    [Settings]
    gtk-theme-name=${gtkTheme}
    gtk-application-prefer-dark-theme=1
    gtk-cursor-theme-name=${cursorTheme}
    gtk-cursor-theme-size=${toString cursorSize}
  '';
in {
  environment.systemPackages = [
    (pkgs.catppuccin-gtk.override {
      accents = ["mauve"];
      variant = "mocha";
    })
    pkgs.catppuccin-cursors.mochaMauve
    (pkgs.writeTextDir "share/icons/default/index.theme" ''
      [Icon Theme]
      Name=Default
      Inherits=${cursorTheme}
    '')
  ];
  environment.pathsToLink = ["/share/themes" "/share/icons"];
  environment.sessionVariables = {
    XCURSOR_THEME = cursorTheme;
    XCURSOR_SIZE = toString cursorSize;
  };
  environment.etc."xdg/gtk-3.0/settings.ini".text = gtkSettings;
  environment.etc."xdg/gtk-4.0/settings.ini".text = gtkSettings;
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = gtkTheme;
        cursor-theme = cursorTheme;
        cursor-size = lib.gvariant.mkInt32 cursorSize;
      };
    }
  ];
}
