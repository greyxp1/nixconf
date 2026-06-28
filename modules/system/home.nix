{config, inputs, lib, ...}: let
  flakeConfig = config;
in {
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };

  options.flake.homeProfiles = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };

  config.flake.nixosModules.home = {...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      overwriteBackup = true;
      extraSpecialArgs = {inherit inputs;};
      users.grey = {...}: {
        imports = builtins.attrValues flakeConfig.flake.homeModules;
        xdg.enable = true;
        home = {
          username = "grey";
          homeDirectory = "/home/grey";
          stateVersion = "26.05";
        };
      };
    };
  };
}
