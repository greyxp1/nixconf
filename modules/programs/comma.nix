{inputs, ...}: {
  flake.nixosModules.comma = {...}: {
    home-manager = {
      sharedModules = [inputs.nix-index-database.homeModules.nix-index];
      users.grey = {...}: {
        programs.nix-index.enable = true;
        programs.nix-index-database.comma.enable = true;
      };
    };
  };
}
