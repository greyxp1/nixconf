{ device, ... }: {
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
}
