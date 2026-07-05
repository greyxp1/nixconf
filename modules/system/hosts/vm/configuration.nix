{inputs, ...}: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.vm = mkHost {
    hostModule = {pkgs, ...}: {
      networking.hostName = "vm";
      custom.disk.device = import ./_device.nix;

      boot = {
        kernelParams = ["8250.nr_uarts=0"];
        kernelModules = ["virtio_gpu"];
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

      services.seatd = {
        enable = true;
        group = "seat";
      };

      users.users.greeter.extraGroups = ["seat" "video" "render"];
      programs.noctalia-greeter.settings = {
        output = {
          name = "Virtual-1";
          scale = 1.0;
        };
        cursor.size = 24;
      };

      systemd.services.greetd = {
        wants = ["seatd.service"];
        after = ["seatd.service"];
        environment = {
          LIBSEAT_BACKEND = "seatd";
          WLR_NO_HARDWARE_CURSORS = "1";
        };
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
        sessionVariables = {
          WLR_NO_HARDWARE_CURSORS = "1";
          LIBSEAT_BACKEND = "seatd";
          LIBGL_ALWAYS_SOFTWARE = "true";
        };
      };

    };
  };
}
