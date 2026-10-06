{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.laptop = mkHost "laptop" ({lib, ...}: let
    bind = command: lib.mkForce (_: {
      props.repeat = false;
      content.spawn = command;
    });
  in {
    imports = [./_hardware.nix inputs.self.wrappers.foot.install];

    services.upower.enable = true;
    programs.git.enable = true;
    users.users.grey.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNpHu5c/ykb/08PRxkU63jqkrn/F7FbSzHh6QqfnwC3 grey@desktop"
    ];
    networking.firewall = {
      extraCommands = "iptables -I nixos-fw 1 -s 192.168.1.6/32 -p tcp --dport 22 -j nixos-fw-accept";
      extraStopCommands = "iptables -D nixos-fw -s 192.168.1.6/32 -p tcp --dport 22 -j nixos-fw-accept || true";
    };
    nix.settings = {
      max-jobs = 1;
      cores = 1;
    };
    wrappers = {
      kitty.enable = lib.mkForce false;
      foot.enable = true;
      niri.settings.binds = {
        "Mod+Return" = bind ["foot"];
        "Mod+Escape" = bind ["foot" "btm"];
        "Mod+E" = bind ["foot" "nu" "-e" "y"];
      };
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

    nixpkgs.overlays = lib.mkAfter [
      (_: prev: {
        niri = prev.niri.overrideAttrs (old: {
          # Avoid the memory-heavy release link on this 4 GiB laptop.
          env = (old.env or {}) // {
            CARGO_PROFILE_RELEASE_LTO = "false";
            CARGO_PROFILE_RELEASE_DEBUG = "0";
          };
        });
      })
    ];

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
