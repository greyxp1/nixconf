{
  config,
  inputs,
  ...
}: let
  homeModules = builtins.attrValues config.flake.homeModules;
  mkAlmaSystemConfig = {
    uid,
    gid,
    primaryGroup,
    flakeLocation ? config.flake.location,
  }:
    inputs.system-manager.lib.makeSystemConfig {
      overlays = [
        inputs.niri.overlays.default
        inputs.niri-screenshare.overlays.default
      ];
      specialArgs = {
        inherit flakeLocation gid homeModules inputs primaryGroup uid;
      };
      modules = [
        ({pkgs, ...}: {
          environment.variables = {
            EDITOR = "hx";
            VISUAL = "hx";
          };
          environment.systemPackages = [
            (config.flake.wrappers.helix.wrap {
              inherit pkgs;
              inherit flakeLocation;
              nixconfSystem = "systemConfigs.alma";
            })
            (config.flake.wrappers.yazi.wrap {
              inherit pkgs;
            })
            (config.flake.wrappers.bottom.wrap {
              inherit pkgs;
              diskRatio = 2;
              settings.disk.mount_filter.is_list_ignored = inputs.nixpkgs.lib.mkForce true;
            })
          ];
        })
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
    # alma-rebuild call mkAlmaSystemConfig with the native account IDs.
    systemConfigs.alma = mkAlmaSystemConfig {
      uid = 1000;
      gid = 1000;
      primaryGroup = "grey";
    };
  };
}
