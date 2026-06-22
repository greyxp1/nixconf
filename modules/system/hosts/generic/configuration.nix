{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.generic = mkHost {
    hostModule = {...}: {
      networking.hostName = "generic";
      custom.disk.device = import ./_device.nix;
      vaultix.settings.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII3HtkPc1+ScFW386XtVRmxjUI9RWddW+QIa5bBy3bDM";
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
      boot.kernelModules = [
        "kvm-amd"
        "kvm-intel"
      ];
    };
  };
}
