{inputs, ...}: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.desktop = mkHost {
    hostModule = {
      networking.hostName = "desktop";
      custom.disk.device = import ./_device.nix;
      custom.audio.enable = true;
      custom.gaming.enable = true;
      custom.kovaaks.enable = true;
      custom.nvidia.enable = true;
      custom.virt.enable = true;

      services.scx.enable = true;
      hardware.cpu.amd.updateMicrocode = true;
      boot = {
        kernelModules = ["kvm-amd" "ntsync"];
        kernelParams = [
          "amd_pstate=active" # AMD CPU freq scaling driver
          "8250.nr_uarts=0" # suppress legacy COM port probes
          "nowatchdog" # disable hardware watchdog drivers
          "nmi_watchdog=0" # disable NMI watchdog
        ];

        initrd = {
          systemd.network.wait-online.enable = false;
          availableKernelModules = ["nvme"];
        };

        loader.systemd-boot.extraEntries."windows.conf" = ''
          title Windows Boot Manager
          efi /EFI/Microsoft/Boot/bootmgfw.efi
        '';
      };

      powerManagement = {
        cpuFreqGovernor = "performance";
        scsiLinkPolicy = "max_performance";
      };
    };
  };
}
