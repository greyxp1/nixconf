{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.desktop = mkHost "desktop" {
    disko.devices.disk.main.device = import ./_device.nix;
    hardware.cpu.amd.updateMicrocode = true;
    powerManagement.cpuFreqGovernor = "performance";

    services.journald.settings.Journal.SyncIntervalSec = "30s";
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
      (inputs.import-tree ../../core)
      (inputs.import-tree ../../desktop)
      ./_modules/sshfs.nix
      ./_modules/sunshine.nix
      ./_modules/cachix-publisher.nix
      ./_modules/noctalia.nix
      ./_modules/at2005usb.nix
      ./_modules/whisrs.nix
      ./_modules/gaming.nix
      ./_modules/kovaaks.nix
      ./_modules/sober.nix
      ./_modules/nvidia.nix
      ./_modules/virt.nix
    ];
  };
}
