{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.laptop = mkHost "laptop" ({lib, ...}: {
    imports = [
      inputs.self.nixosModules.profile-desktop
      inputs.self.nixosModules.sunshine
      ./_hardware.nix
    ];

    services.upower.enable = true;
    programs.git.enable = true;
    users.users.grey.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNpHu5c/ykb/08PRxkU63jqkrn/F7FbSzHh6QqfnwC3 grey@desktop"
    ];
    networking.firewall = {
      extraCommands = "iptables -I nixos-fw 1 -s 192.168.1.3/32 -p tcp --dport 22 -j nixos-fw-accept";
      extraStopCommands = "iptables -D nixos-fw -s 192.168.1.3/32 -p tcp --dport 22 -j nixos-fw-accept || true";
    };
    wrappers = {
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

    boot.loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
      grub.enable = true;
    };
  });
}
