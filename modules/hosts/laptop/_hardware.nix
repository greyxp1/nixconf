{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot = {
    loader.grub.devices = lib.mkForce ["/dev/disk/by-id/ata-SATA3_128GB_SSD_2021071200216"];
    kernelModules = ["kvm-intel"];
    initrd.availableKernelModules = [
      "ahci"
      "sd_mod"
      "sr_mod"
      "ehci_pci"
      "ehci_hcd"
      "usb_storage"
      "usbhid"
    ];
  };
}
