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
    systemd.user.services.niri-screenshare = {
      enableDefaultPath = false;
      wantedBy = ["graphical-session.target"];
    };
  };
}
