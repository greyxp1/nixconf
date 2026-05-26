{ inputs, ... }: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.vm = mkHost {
    hostModule = { pkgs, lib, ... }: {
      networking.hostName = "vm";
      custom.disk.device = "/dev/vda";

      boot = {
        kernelModules = [ "virtio_gpu" ];
        initrd.availableKernelModules = [
          "virtio_pci"
          "virtio_blk"
          "virtio_scsi"
          "virtio_gpu"
          "virtio_balloon"
          "ahci"
          "sd_mod"
        ];
      };

      # seatd handles DRM device ownership — required for niri TTY backend in VM
      services.seatd = {
        enable = true;
        group = "seat";
      };

      # greetd must run niri-session after seatd is up
      systemd.services.greetd = {
        after = lib.mkForce [
          "multi-user.target"
          "seatd.service"
        ];
        wants = [ "seatd.service" ];
      };

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [ mesa ];
      };

      services = {
        spice-vdagentd.enable = true;
        qemuGuest.enable = true;
      };

      environment = {
        sessionVariables = {
          WLR_NO_HARDWARE_CURSORS = "1";
          LIBSEAT_BACKEND = "seatd";
        };
        systemPackages = with pkgs; [ spice-vdagent ];
      };
    };
  };
}
