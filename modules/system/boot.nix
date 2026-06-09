{inputs, ...}: {
  flake.nixosModules.boot = {pkgs, ...}: {
    nixpkgs.overlays = [inputs.mac-style-plymouth.overlays.default];

    boot = {
      plymouth = {
        enable = true;
        theme = "mac-style";
        themePackages = [pkgs.mac-style-plymouth];
      };

      supportedFilesystems = ["btrfs"];
      initrd = {
        supportedFilesystems = ["btrfs"];
        systemd.enable = true;
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
