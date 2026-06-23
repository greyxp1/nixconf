{inputs, ...}: let
  mkLayout = device: {
    disko.devices.disk.main = {
      type = "disk";
      inherit device;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              extraArgs = ["-F" "32" "-n" "NIXBOOT"];
              mountOptions = ["umask=0077"];
            };
          };
          swap = {
            size = "8G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = ["-f" "--label" "nixos"];
              subvolumes = {
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@persistent" = {
                  mountpoint = "/persistent";
                  mountOptions = ["compress=zstd" "noatime"];
                };
              };
            };
          };
        };
      };
    };
  };
in {
  flake.nixosModules.filesystem = {lib, config, ...}: {
    imports = [
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.preservation
      (mkLayout config.custom.disk.device)
    ];

    options.custom.disk.device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/sda";
      description = "Disk device for manual disko re-runs. Boot uses labels so this doesn't affect normal operation.";
    };

    config = {
      systemd.services.systemd-machine-id-commit.enable = false;
      fileSystems = lib.mkForce {
        "/" = {
          device = "none";
          fsType = "tmpfs";
          options = ["defaults" "size=4G" "mode=755"];
        };
        "/nix" = {
          device = "LABEL=nixos";
          fsType = "btrfs";
          options = ["subvol=@nix" "compress=zstd" "noatime"];
          neededForBoot = true;
        };
        "/home" = {
          device = "LABEL=nixos";
          fsType = "btrfs";
          options = ["subvol=@home" "compress=zstd" "noatime"];
        };
        "/persistent" = {
          device = "LABEL=nixos";
          fsType = "btrfs";
          options = ["subvol=@persistent" "compress=zstd" "noatime"];
          neededForBoot = true;
        };
        "/boot" = {
          device = "/dev/disk/by-label/NIXBOOT";
          fsType = "vfat";
          options = ["umask=0077"];
        };
      };

      preservation = {
        enable = true;
        preserveAt."/persistent" = {
          directories = [
            {
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
            "/var/lib/NetworkManager"
            "/var/lib/bluetooth"
            "/var/lib/libvirt"
            "/var/lib/sbctl"
            "/var/log"
          ];
          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
          ];
        };
      };
    };
  };

  flake.diskoConfigurations = {
    desktop = mkLayout (import ./hosts/desktop/_device.nix);
    vm = mkLayout (import ./hosts/vm/_device.nix);
    generic = mkLayout (import ./hosts/generic/_device.nix);
  };
}
