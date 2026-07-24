{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.vm = mkHost "vm" {
    environment.sessionVariables.LIBGL_ALWAYS_SOFTWARE = "true";
    services.qemuGuest.enable = true;
    boot = {
      kernelModules = ["virtio_gpu"];
      initrd.availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
        "virtio_scsi"
        "sd_mod"
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
