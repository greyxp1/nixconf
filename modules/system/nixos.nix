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
          trusted-users = ["@wheel"];
          experimental-features = ["nix-command" "flakes"];
          warn-dirty = false;
        }
        // import ./_cache.nix;
    };

    systemd.services.nix-daemon.serviceConfig = {
      MemoryHigh = "70%";
      MemoryMax = "85%";
      OOMScoreAdjust = 500;
    };

    system = {
      nixos.label = config.networking.hostName;
      stateVersion = "26.05";
    };
  };
}
