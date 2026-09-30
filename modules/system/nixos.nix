{
  flake.nixosModules.nixos = {
    config,
    pkgs,
    ...
  }: {
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    security.sudo.extraConfig = ''
      Defaults secure_path="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"
    '';

    nix = {
      package = pkgs.lix;
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
      settings =
        {
          max-jobs = 2;
          cores = 6;
          trusted-users = ["@wheel"];
          experimental-features = ["nix-command" "flakes"];
          warn-dirty = false;
        }
        // import ./_cache.nix;
    };

    system = {
      nixos.label = config.networking.hostName;
      stateVersion = "26.05";
    };
  };
}
