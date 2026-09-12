{
  config,
  inputs,
  ...
}: let
  homeModules = builtins.attrValues config.flake.homeModules;
  mkAlmaSystemConfig = {
    username,
    uid,
    gid,
    primaryGroup,
    homeDirectory ? "/home/${username}",
    flakeLocation ? config.flake.location,
  }:
    inputs.system-manager.lib.makeSystemConfig {
      overlays = [
        inputs.niri.overlays.default
        inputs.niri-screenshare.overlays.default
      ];
      specialArgs = {
        inherit flakeLocation gid homeDirectory homeModules inputs primaryGroup uid username;
      };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        ./_modules/home.nix
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
    # alma-rebuild call mkAlmaSystemConfig with the actual native account.
    systemConfigs.alma = mkAlmaSystemConfig {
      username = "grey";
      uid = 1000;
      gid = 1000;
      primaryGroup = "grey";
    };
  };
}
