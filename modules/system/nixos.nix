{
  flake.nixosModules.core = {config, pkgs, ...}: {
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    programs.nix-ld.enable = true;

    nix = {
      package = pkgs.lix;
      settings = {
        trusted-users = ["@wheel"];
        experimental-features = ["nix-command" "flakes"];
        warn-dirty = false;
      } // import ./_cache.nix;
    };

    system = {
      nixos.label = config.networking.hostName;
      stateVersion = "26.05";
    };
  };
}
