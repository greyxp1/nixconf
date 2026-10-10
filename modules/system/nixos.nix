{
  flake.nixosModules.nixos = {
    config,
    pkgs,
    ...
  }: let
    daemonResources = {
      Slice = "nixbuild.slice";
      Nice = 19;
      OOMScoreAdjust = 500;
    };
  in {
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    hardware.block.defaultScheduler = "mq-deadline";
    security.sudo.extraConfig = ''
      Defaults secure_path="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"
    '';

    nix = {
      package = pkgs.lix;
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
      settings = {
        trusted-users = ["@wheel"];
        experimental-features = ["nix-command" "flakes"];
        warn-dirty = false;
        max-jobs = 1;
        cores = 0;
      };
    };

    systemd = {
      services.systemd-udevd.postStart = "${pkgs.systemd}/bin/udevadm trigger --subsystem-match=block --action=change";
      services.nix-daemon.serviceConfig = daemonResources;
      services."nix-daemon@".serviceConfig = daemonResources;
      slices.nixbuild.sliceConfig = {
        CPUWeight = "idle";
        MemoryHigh = "50%";
        MemoryMax = "60%";
        MemorySwapMax = 0;
      };
    };

    system = {
      nixos.label = config.networking.hostName;
      stateVersion = "26.05";
    };
  };
}
