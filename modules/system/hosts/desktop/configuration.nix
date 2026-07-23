{inputs, ...}: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.desktop = mkHost "desktop" {
    disko.devices.disk.main.device = import ./_device.nix;
    services.scx.enable = true;
    hardware.cpu.amd.updateMicrocode = true;
    powerManagement.cpuFreqGovernor = "performance";
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

    imports = [
      ./_modules/at2005usb.nix
      ./_modules/steam.nix
      ./_modules/kovaaks.nix
      ./_modules/nvidia.nix
      ./_modules/virt.nix
    ];

    home-manager.sharedModules = [
      ./_modules/niri.nix
      ./_modules/noctalia.nix
    ];
  };
}
