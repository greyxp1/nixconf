{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.generic = mkHost "generic" {
    imports = [inputs.self.nixosModules.profile-desktop inputs.self.nixosModules.sunshine];
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
