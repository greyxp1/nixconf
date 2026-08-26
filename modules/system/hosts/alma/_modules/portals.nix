{
  config,
  lib,
  pkgs,
  ...
}: {
  systemd.user = {
    sessionVariables.XDG_DESKTOP_PORTAL_DIR = "${config.home.profileDirectory}/share/xdg-desktop-portal/portals";
    services.xdg-desktop-portal-termfilechooser = {
      Unit = {
        Description = "Terminal file chooser portal";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.termfilechooser";
        ExecStart = "${pkgs.xdg-desktop-portal-termfilechooser}/libexec/xdg-desktop-portal-termfilechooser";
        Restart = "on-failure";
      };
    };
  };

  wayland.windowManager.niri.portalPackage = null;
  xdg = {
    configFile =
      lib.genAttrs (map (component: "autostart/gnome-keyring-${component}.desktop") [
        "pkcs11"
        "secrets"
        "ssh"
      ]) (_: {
        text = ''
          [Desktop Entry]
          Hidden=true
        '';
      });
    dataFile =
      lib.mapAttrs (_: name: {
        text = ''
          [D-BUS Service]
          Name=${name}
          Exec=/usr/bin/false
        '';
      }) {
        "dbus-1/services/org.freedesktop.impl.portal.Secret.service" = "org.freedesktop.impl.portal.Secret";
        "dbus-1/services/org.freedesktop.secrets.service" = "org.freedesktop.secrets";
      };
    mimeApps = {
      enable = true;
      associations.removed."inode/directory" = ["kitty-open.desktop"];
      defaultApplications."inode/directory" = ["yazi.desktop"];
    };
    portal = {
      enable = true;
      config.niri = {
        default = "gtk";
        "org.freedesktop.impl.portal.FileChooser" = lib.mkForce ["termfilechooser"];
        "org.freedesktop.impl.portal.ScreenCast" = "niri";
        "org.freedesktop.impl.portal.Secret" = lib.mkForce "none";
      };
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-termfilechooser
        # Alma's native broker uses XDG_DESKTOP_PORTAL_DIR for both
        # backend descriptors and policy lookup.
        (pkgs.writeTextDir "share/xdg-desktop-portal/portals/niri-portals.conf" ''
          [preferred]
          default=gtk
          org.freedesktop.impl.portal.FileChooser=termfilechooser
          org.freedesktop.impl.portal.ScreenCast=niri
          org.freedesktop.impl.portal.Secret=none
        '')
        (lib.lowPrio ((pkgs.niri-screenshare.override {withPicker = false;}).overrideAttrs {
          cargoBuildNoDefaultFeatures = true;
          cargoCheckNoDefaultFeatures = true;
        }))
      ];
    };
  };
}
