{inputs, ...}: let
  mkAlmaSystemConfig = {
    uid,
    gid,
    primaryGroup,
  }:
    inputs.system-manager.lib.makeSystemConfig {
      overlays = [
        inputs.niri.overlays.default
        inputs.niri-screenshare.overlays.default
      ];
      specialArgs = {
        inherit gid inputs primaryGroup uid;
      };
      modules = [
        ./_modules/desktop.nix
        ./_modules/host.nix
      ];
    };
in {
  perSystem = {system, ...}: {
    packages.system-manager = inputs.system-manager.packages.${system}.default;
  };

  flake = {
    lib.mkAlmaSystemConfig = mkAlmaSystemConfig;
    # Keep a pure, stable output for checks and cache builds. The installer and
    # alma-rebuild call mkAlmaSystemConfig with the native account IDs.
    systemConfigs.alma = mkAlmaSystemConfig {
      uid = 1000;
      gid = 1000;
      primaryGroup = "grey";
    };
  };
}
