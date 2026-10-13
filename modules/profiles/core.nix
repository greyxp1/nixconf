{inputs, ...}: {
  flake.nixosModules.profile-core = {
    wrappers.nushell.integrations.yazi.enable = true;
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
      wrappers.helix.install
      wrappers.bottom.install
      wrappers.nushell.install
      wrappers.starship.install
    ];
  };
}
