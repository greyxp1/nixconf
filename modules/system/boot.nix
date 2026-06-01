{ ... }: {
  flake.nixosModules.boot = { ... }: {
    systemd.network.wait-online.enable = false;

    boot = {
      supportedFilesystems = [ "btrfs" ];
      initrd.supportedFilesystems = [ "btrfs" ];
      initrd.systemd.enable = true;

      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
        timeout = 0;
      };
    };
  };
}
