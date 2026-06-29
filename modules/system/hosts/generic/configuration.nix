{inputs, ...}: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.generic = mkHost {
    hostModule = {
      networking.hostName = "generic";
      custom.disk.device = import ./_device.nix;
      boot.kernelModules = ["kvm-amd" "kvm-intel"];
      boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "nvme"
        "usb_storage"
        "usbhid"
        "sd_mod"
        "virtio_pci"
        "virtio_blk"
      ];
    };
  };
}
