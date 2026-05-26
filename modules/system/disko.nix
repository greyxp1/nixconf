{ ... }: {
  flake.nixosModules.disk = { lib, config, ... }: {
    options.custom.disk.device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/sda";
      description = "Disk device for manual disko re-runs. Boot uses labels, so this doesn't affect normal operation.";
    };

    config = {
      disko.devices.disk.main = {
        type   = "disk";
        device = config.custom.disk.device;
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
                extraArgs = [ "-F" "32" "-n" "NIXBOOT" ];
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "8G";
              content = { type = "swap"; resumeDevice = true; };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "--label" "nixos" ];
                subvolumes = {
                  "@nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "@home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "@persistent" = { mountpoint = "/persistent"; mountOptions = [ "compress=zstd" "noatime" ]; };
                };
              };
            };
          };
        };
      };

      fileSystems = lib.mkForce {
        "/" = {
          device = "none";
          fsType = "tmpfs";
          options = [ "defaults" "size=4G" "mode=755" ];
        };
        "/nix" = {
          device = "LABEL=nixos";
          fsType = "btrfs";
          options = [ "subvol=@nix" "compress=zstd" "noatime" ];
          neededForBoot = true;
        };
        "/home" = {
          device = "LABEL=nixos";
          fsType = "btrfs";
          options = [ "subvol=@home" "compress=zstd" "noatime" ];
        };
        "/persistent" = {
          device = "LABEL=nixos";
          fsType = "btrfs";
          options = [ "subvol=@persistent" "compress=zstd" "noatime" ];
          neededForBoot = true;
        };
        "/boot" = {
          device = "/dev/disk/by-label/NIXBOOT";
          fsType = "vfat";
          options = [ "umask=0077" ];
        };
      };
    };
  };
}
