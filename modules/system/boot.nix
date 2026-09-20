{
  flake.nixosModules.boot = {lib, ...}: {
    boot = {
      kernelParams = ["systemd.show_status=auto"];
      consoleLogLevel = 3;
      loader = {
        efi.canTouchEfiVariables = lib.mkDefault true;
        systemd-boot.enable = lib.mkDefault true;
        timeout = 0;
      };
    };
  };
}
