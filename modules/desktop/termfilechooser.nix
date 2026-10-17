{
  pkgs,
  lib,
  ...
}: {
  imports = [../_custom-modules/termfilechooser.nix];
  xdg.portal.termfilechooser.enable = true;
  xdg.portal.config.niri."org.freedesktop.impl.portal.FileChooser" = lib.mkForce ["termfilechooser"];
  xdg.portal.termfilechooser.settings.filechooser = {
    cmd = "${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh";
    default_dir = "$HOME";
    env = "TERMCMD=monstar -o background-opacity=0.6 --title=filepicker -e";
  };
}
