{
  importTree,
  lib,
  ...
}: {
  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "performance";

  services.journald.settings.Journal = {
    SystemMaxUse = lib.mkForce "2G";
    # Rotate system and application logs together so noisy apps cannot evict only the system logs.
    SplitMode = "none";
    SyncIntervalSec = "30s";
  };
  programs.atop.enable = true;
  systemd.services.atop = {
    environment = {
      LOGINTERVAL = "10";
      LOGGENERATIONS = "7";
      LOGOPTS = "-a";
    };
    serviceConfig.StandardOutput = "null";
  };

  boot = {
    kernelModules = ["kvm-amd" "ntsync"];
    kernelParams = [
      "amd_pstate=active" # AMD CPU freq scaling driver
      "8250.nr_uarts=0" # suppress legacy COM port probes
    ];

    initrd = {
      systemd.network.wait-online.enable = false;
      availableKernelModules = ["nvme"];
    };
  };

  services.scx = {
    enable = true;
    scheduler = "scx_cosmos";
  };

  imports = [
    (importTree ../../core)
    (importTree ../../desktop)
    ./_modules/sshfs.nix
    ./_modules/sunshine.nix
    ./_modules/cachix-publisher.nix
    ./_modules/noctalia.nix
    ./_modules/recording.nix
    ./_modules/at2005usb.nix
    ./_modules/whisrs.nix
    ./_modules/gaming.nix
    ./_modules/kovaaks.nix
    ./_modules/sober.nix
    ./_modules/nvidia.nix
    ./_modules/virt.nix
    ./_modules/remote-builder.nix
  ];
}
