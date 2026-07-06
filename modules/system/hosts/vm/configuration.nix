{inputs, ...}: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.vm = mkHost {
    hostModule = {pkgs, ...}: {
      networking.hostName = "vm";
      custom.disk.device = import ./_device.nix;

      boot = {
        kernelModules = ["virtio_gpu"];
        initrd.availableKernelModules = [
          "virtio_pci"
          "virtio_blk"
          "virtio_scsi"
          "sd_mod"
        ];
      };

      services.seatd = {
        enable = true;
        group = "seat";
      };

      users.users.greeter.extraGroups = ["seat" "video" "render"];

      systemd.services.greetd = {
        wants = ["seatd.service"];
        after = ["seatd.service"];
      };

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [mesa];
      };

      services = {
        spice-vdagentd.enable = true;
        qemuGuest.enable = true;
      };

      environment = {
        systemPackages = with pkgs; [spice-vdagent];
        sessionVariables.LIBGL_ALWAYS_SOFTWARE = "true";
      };
    };
  };
}
