{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.generic = mkHost "generic" {
    imports = [inputs.self.nixosModules.profile-desktop];
    services.qemuGuest.enable = true;
    boot = {
      kernelModules = ["virtio_gpu"];
      initrd.availableKernelModules = [
        "ahci"
        "ata_piix"
        "xhci_pci"
        "nvme"
        "usb_storage"
        "usbhid"
        "sd_mod"
        "virtio_pci"
        "virtio_blk"
        "virtio_scsi"
      ];
    };
    disko.devices.disk.main = {
      device = import ./_device.nix;
      content.partitions.swap = {
        size = "8G";
        content.type = "swap";
      };
    };
  };
}
