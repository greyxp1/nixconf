# Generated for the laptop hardware.
{config, lib, modulesPath, ...}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = [
    "ahci"
    "sd_mod"
    "sr_mod"
    "ehci_pci"
    "ehci_hcd"
    "usb_storage"
    "usbhid"
  ];
  boot.kernelModules = ["kvm-intel"];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
