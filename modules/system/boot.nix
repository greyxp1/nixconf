{
  flake.nixosModules.boot = {
    boot = {
      supportedFilesystems = ["btrfs"];
      initrd = {
        supportedFilesystems = ["btrfs"];
        verbose = false;
      };

      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
        timeout = 0;
      };

      consoleLogLevel = 3;
      kernelParams = [
        "quiet"
        "udev.log_level=3"
        "systemd.show_status=auto"
        "vt.global_cursor_default=0"
      ];
    };
  };
}
