{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.laptop = mkHost "laptop" {
    disko.devices.disk.main = {
      device = import ./_device.nix;
      content.partitions = {
        bios = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };
        ESP = {
          name = "boot";
          size = "1G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/boot";
          };
        };
      };
    };

    boot = {
      loader = {
        systemd-boot.enable = false;
        efi.canTouchEfiVariables = false;
        grub.enable = true;
      };
      initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "ehci_pci"
        "nvme"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
    };
  };
}
