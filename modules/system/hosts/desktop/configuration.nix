{inputs, ...}: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.desktop = mkHost {
    extraModules = [
      inputs.lanzaboote.nixosModules.lanzaboote
      ./_audio.nix
      ./_virt.nix
      ./gaming/_gaming.nix
      ./gaming/kovaaks/_kovaaks.nix
      ./_nvidia.nix
    ];
    hostModule = {pkgs, lib, ...}: {
      networking.hostName = "desktop";
      custom.disk.device = import ./_device.nix;

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

      # Secure Boot
      environment.systemPackages = [pkgs.sbctl];
      boot = {
        loader.systemd-boot.enable = lib.mkForce false;
        lanzaboote = {
          enable = true;
          autoGenerateKeys.enable = true;
          pkiBundle = "/var/lib/sbctl";
          configurationLimit = 10;
          autoEnrollKeys.enable = true;
          autoEnrollKeys.autoReboot = true;
        };
      };
    };
  };
}
