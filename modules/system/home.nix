{
  config,
  inputs,
  lib,
  ...
}: {
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };

  config.flake.nixosModules.home = {
    homeDirectory,
    username,
    ...
  }: {
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
      users.${username}.home = {
        inherit homeDirectory username;
        stateVersion = "26.05";
      };
    };
  };
}
