{ ... }: {
  flake.nixosModules.disk = { lib, config, ... }: {
    imports = [ (import ./disk-layout.nix { device = config.custom.disk.device; }) ];

    options.custom.disk.device = lib.mkOption {
      type        = lib.types.str;
      default     = "/dev/sda";
      description = "Disk device for manual disko re-runs. Boot uses labels so this doesn't affect normal operation.";
    };

    config.fileSystems = lib.mkForce {
      "/"          = { device = "none";           fsType = "tmpfs"; options = [ "defaults" "size=4G" "mode=755" ]; };
      "/nix"       = { device = "LABEL=nixos";    fsType = "btrfs"; options = [ "subvol=@nix"        "compress=zstd" "noatime" ]; neededForBoot = true; };
      "/home"      = { device = "LABEL=nixos";    fsType = "btrfs"; options = [ "subvol=@home"       "compress=zstd" "noatime" ]; };
      "/persistent"= { device = "LABEL=nixos";    fsType = "btrfs"; options = [ "subvol=@persistent" "compress=zstd" "noatime" ]; neededForBoot = true; };
      "/boot"      = { device = "/dev/disk/by-label/NIXBOOT"; fsType = "vfat"; options = [ "umask=0077" ]; };
    };
  };

  flake.diskoConfigurations = {
    vm      = import ./disk-layout.nix { device = import ./hosts/vm/_device.nix; };
    desktop = import ./disk-layout.nix { device = import ./hosts/desktop/_device.nix; };
    generic = import ./disk-layout.nix { device = import ./hosts/generic/_device.nix; };
  };
}
