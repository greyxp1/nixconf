{
  flake.nixosModules.boot = {
    boot = {
      supportedFilesystems = ["btrfs"];
      initrd.supportedFilesystems = ["btrfs"];
      kernelParams = ["systemd.show_status=auto"];
      consoleLogLevel = 3;
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
        timeout = 0;
      };
    };
  };
}
