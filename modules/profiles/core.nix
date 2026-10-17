{inputs, ...}: {
  flake.nixosModules.profile-core = {
    imports = with inputs.self; [
      nixosModules.nixos
      nixosModules.system
      nixosModules.boot
      nixosModules.filesystem
      nixosModules.preservation
      nixosModules.cli
      nixosModules.ssh
      nixosModules.git
      nixosModules.yazi
      nixosModules.nushell
      nixosModules.starship
      nixosModules.helix
      nixosModules.bottom
    ];
  };
}
