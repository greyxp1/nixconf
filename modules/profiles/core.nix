{inputs, ...}: {
  flake.nixosModules.profile-core = {
    imports = with inputs.self.nixosModules; [
      nixos
      system
      boot
      filesystem
      preservation
      cachix
      ssh
      tailscale
      cli
      git
      helix
      bottom
      nushell
      starship
      t3code
    ];
  };
}
