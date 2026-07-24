inputs: hostName: hostModule: let
  username = "grey";
  homeDirectory = "/home/${username}";
in
  inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit homeDirectory inputs username;};
    modules =
      [
        {networking.hostName = hostName;}
        hostModule
      ]
      ++ builtins.attrValues inputs.self.nixosModules;
  }
