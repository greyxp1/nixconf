{inputs, ...}: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.vm = mkHost {
    hostModule = {
      networking.hostName = "vm";
      custom.disk.device = import ./_device.nix;
      environment.sessionVariables.LIBGL_ALWAYS_SOFTWARE = "true";
      hardware.graphics.enable = true;
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
    };
  };
}
