{ ... }:
{
  flake.nixosModules.boot =
    { ... }:
    {
      systemd.network.wait-online.enable = false;

      boot = {
        supportedFilesystems = [ "btrfs" ];
        initrd.supportedFilesystems = [ "btrfs" ];

        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = true;
          timeout = 0;
        };
      };
    };
}
