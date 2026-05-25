{ ... }:
{
  flake.nixosModules.performance =
    { ... }:
    {
      security.rtkit.enable = true;
      services.irqbalance.enable = true;

      boot.kernel.sysctl = {
        "vm.swappiness" = 100;
        "vm.page-cluster" = 0;
        "vm.vfs_cache_pressure" = 50;
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        "net.core.netdev_max_backlog" = 16384;
      };

      nix = {
        daemonCPUSchedPolicy = "idle";
        daemonIOSchedClass = "idle";
        settings = {
          max-jobs = "auto";
          cores = 0;
          http-connections = 128;
          download-buffer-size = 1073741824;
          narinfo-cache-negative-ttl = 0;
          builders-use-substitutes = true;
        };
      };
    };
}
