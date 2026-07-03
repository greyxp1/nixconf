{inputs, ...}: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.desktop = mkHost {
    hostModule = {pkgs, ...}: {
      networking.hostName = "desktop";
      custom.disk.device = import ./_device.nix;
      custom.audio.enable = true;
      custom.gaming.enable = true;
      custom.kovaaks.enable = true;
      custom.nvidia.enable = true;
      custom.virt.enable = true;

      # Kernel
      nixpkgs.overlays = [inputs.nix-cachyos-kernel.overlays.pinned];
      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;

      # AMD CPU
      powerManagement.cpuFreqGovernor = "performance";
      hardware.cpu.amd.updateMicrocode = true;
      boot.kernelParams = [
        "amd_pstate=active" # AMD CPU freq scaling driver
        "8250.nr_uarts=0" # suppress legacy COM port probes
        "nowatchdog" # disable hardware watchdog drivers
        "nmi_watchdog=0" # disable NMI watchdog
      ];

      # Disable TPM
      systemd.services = {
        systemd-tpm2-setup.enable = false;
        systemd-tpm2-setup-early.enable = false;
      };

      # Boot / initrd
      boot = {
        kernelModules = ["kvm-amd"];
        initrd = {
          systemd.network.wait-online.enable = false;
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "usb_storage"
            "usbhid"
            "sd_mod"
          ];
        };
      };
    };
  };
}
