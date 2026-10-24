{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.laptop = mkHost "laptop" ({lib, ...}: {
    imports = [
      (inputs.import-tree ../../core)
      (inputs.import-tree ../../desktop)
      ./_hardware.nix
      ./_network.nix
    ];

    swapDevices = [
      {
        device = "/persistent/swapfile";
        size = 8192;
      }
    ];

    services.upower.enable = true;
    boot.loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
      grub.enable = true;
    };

    disko.devices.disk.main = {
      device = import ./_device.nix;
      content.partitions = {
        bios = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };
        ESP = {
          name = "boot";
          size = "1G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/boot";
          };
        };
      };
    };

    programs = {
      noctalia.settings = {
        bar.default = {
          margin_ends = lib.mkForce 32;
          scale = lib.mkForce 1.0;
          start = lib.mkForce [];
        };
        plugin_settings."noctalia/screen_recorder".replay_enabled = lib.mkForce false;
        hooks.started = lib.mkForce ''
          noctalia msg session lock
          systemctl --user start xdg-desktop-portal.service niri-screenshare.service
        '';
      };
    };
  });
}
