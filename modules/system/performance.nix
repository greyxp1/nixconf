{
  flake.nixosModules.performance = {
    services.irqbalance.enable = true;
    nix.settings = {
      http-connections = 128;
      nar-buffer-size = 536870912;
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };

    boot.kernel.sysctl = {
      "vm.swappiness" = 100;
      "vm.page-cluster" = 0;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.core.netdev_max_backlog" = 16384;
    };
  };
}
