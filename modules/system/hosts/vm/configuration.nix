{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.vm = mkHost {
    hostModule = {
      pkgs,
      lib,
      ...
    }: {
      networking.hostName = "vm";
      custom.disk.device = import ./_device.nix;
      vaultix.settings.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOaUY3+hgQqTRZwstdsKTSmp7OXXPtx0hods48xWiFeZ";

      boot = {
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

      # seatd handles DRM device ownership — required for niri TTY backend in VM
      services.seatd.enable = true;
      services.seatd.group = "seat";

      # greetd must run niri-session after seatd is up
      systemd.services.greetd = {
        wants = ["seatd.service"];
        after = lib.mkForce [
          "multi-user.target"
          "seatd.service"
        ];
      };

      hardware.graphics.enable = true;
      hardware.graphics.extraPackages = with pkgs; [mesa];

      services.spice-vdagentd.enable = true;
      services.qemuGuest.enable = true;

      environment = {
        sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
        sessionVariables.LIBSEAT_BACKEND = "seatd";
        systemPackages = with pkgs; [spice-vdagent];
      };
    };
  };
}
