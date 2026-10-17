{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot = {
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
