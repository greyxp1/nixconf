{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.disko.nixosModules.disko];
  disko.devices.disk.main = {
    # The installer links the selected disk here.
    device = "/dev/nixos-disk";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = lib.mkDefault {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            extraArgs = ["-F" "32"];
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
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
}
