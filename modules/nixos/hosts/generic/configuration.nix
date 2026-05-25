{ inputs, ... }: {
  flake.nixosConfigurations.generic = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };

    modules = [({ ... }:{
      networking.hostName = "generic";
      custom.disk.device = "/dev/sda";
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
    })]
    ++ builtins.attrValues inputs.self.nixosModules;
  };
}
