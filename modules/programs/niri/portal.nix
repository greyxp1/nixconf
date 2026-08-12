{inputs, ...}: let
  niri-screenshare = pkgs:
    (pkgs.niri-screenshare.override {withPicker = false;}).overrideAttrs {
      cargoBuildNoDefaultFeatures = true;
      cargoCheckNoDefaultFeatures = true;
    };
in {
  flake.nixosModules.niri-portal = {
    lib,
    pkgs,
    ...
  }: {
    nixpkgs.overlays = [inputs.niri-screenshare.overlays.default];
    services.gnome.gnome-keyring.enable = lib.mkForce false;
    xdg.portal = {
      extraPortals = [(niri-screenshare pkgs)];
      config.niri = {
        "org.freedesktop.impl.portal.ScreenCast" = "niri";
        "org.freedesktop.impl.portal.Secret" = lib.mkForce "none";
      };
    };
    environment.pathsToLink = ["/share/xdg-desktop-portal"];
  };

  flake.homeModules.niri-portal = {pkgs, ...}: {
    systemd.user.services.niri-screenshare = {
      Unit = {
        Description = "Portal service (niri backend)";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
        Requisite = ["graphical-session.target"];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.niri";
        ExecStart = "${niri-screenshare pkgs}/bin/niri-screenshare";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
