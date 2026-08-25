{
  config,
  inputs,
  ...
}: let
  username = "grey";
  homeDirectory = "/home/${username}";
  flakeLocation = config.flake.location;
  homeModules = builtins.attrValues config.flake.homeModules;
in {
  perSystem = {system, ...}: {
    packages.system-manager = inputs.system-manager.packages.${system}.default;
  };

  flake.systemConfigs.alma = inputs.system-manager.lib.makeSystemConfig {
    overlays = [
      inputs.niri.overlays.default
      inputs.niri-screenshare.overlays.default
    ];
    modules = [
      inputs.home-manager.nixosModules.home-manager
      (import ./_modules/home.nix {
        inherit flakeLocation homeDirectory homeModules inputs username;
      })
      (import ./_modules/host.nix {
        inherit homeDirectory username;
      })
    ];
  };
}
