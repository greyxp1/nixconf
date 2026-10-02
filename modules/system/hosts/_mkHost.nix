inputs: hostName: hostModule:
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules =
    [
      {networking.hostName = hostName;}
      hostModule
    ]
    ++ builtins.attrValues inputs.self.nixosModules;
}
