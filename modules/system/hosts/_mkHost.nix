inputs: {
  hostModule,
  extraModules ? [],
}:
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules =
    [hostModule]
    ++ builtins.attrValues inputs.self.nixosModules
    ++ extraModules;
}
