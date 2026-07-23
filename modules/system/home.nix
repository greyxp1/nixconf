{config, inputs, lib, ...}: {
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };

  config.flake.nixosModules.home = {
    imports = [inputs.home-manager.nixosModules.home-manager];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      overwriteBackup = true;
      sharedModules = [
        {
          imports = builtins.attrValues config.flake.homeModules;
          xdg.enable = true;
        }
      ];
      users.grey.home = {
        username = "grey";
        homeDirectory = "/home/grey";
        stateVersion = "26.05";
      };
    };
  };
}
