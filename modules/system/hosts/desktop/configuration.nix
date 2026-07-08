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

      boot = {
        kernelModules = ["kvm-amd"];
        loader.systemd-boot.extraEntries."windows.conf" = ''
          title Windows Boot Manager
          efi /EFI/Microsoft/Boot/bootmgfw.efi
        '';

        initrd = {
          systemd.network.wait-online.enable = false;
          availableKernelModules = ["nvme"];
        };
      };
    };
  };
}
