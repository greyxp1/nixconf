{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.generic = mkHost "generic" {
    disko.devices.disk.main.device = import ./_device.nix;
    boot.initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
  };
}
