{importTree, ...}: {
  imports = [
    (importTree ../../core)
    (importTree ../../graphical)
  ];

  services.qemuGuest.enable = true;
  disko.devices.disk.main = {
    content.partitions.swap = {
      size = "8G";
      content.type = "swap";
    };
  };

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
}
