{inputs, ...}: {
  imports = [inputs.vaultix.flakeModules.default];

  perSystem = {system, ...}: {
    _module.args.pkgs = inputs.nixpkgs.legacyPackages.${system};
  };

  flake.vaultix = {
    nodes = inputs.self.nixosConfigurations;
    identity = "/home/grey/.age/key.txt";
  };

  flake.nixosModules.vaultix = _: {
    imports = [inputs.vaultix.nixosModules.default];
  };
}
