{
  config,
  inputs,
  lib,
  ...
}: {
  options.flake.location = lib.mkOption {
    type = lib.types.str;
    default = "/home/grey/Projects/nixconf";
  };

  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };

  config.flake.homeModules.flake-location = {lib, ...}: {
    options.flake.location = lib.mkOption {
      type = lib.types.str;
      default = config.flake.location;
    };
  };

  config.flake.nixosModules.flake-location = {lib, ...}: {
    options.flake.location = lib.mkOption {
      type = lib.types.str;
      default = config.flake.location;
    };
  };

  config.flake.nixosModules.home = {
    imports = [inputs.home-manager.nixosModules.home-manager];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      overwriteBackup = true;
      extraSpecialArgs.nixconfSystem = null;
      sharedModules = [
        {
          imports = builtins.attrValues config.flake.homeModules;
          xdg.enable = true;
        }
      ];
      users.grey.home = {
        homeDirectory = "/home/grey";
        username = "grey";
        stateVersion = "26.05";
      };
    };
  };
}
