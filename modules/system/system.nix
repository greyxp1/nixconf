{
  flake.nixosModules.system = {
    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;
    services = {
      irqbalance.enable = true;
      journald.settings.Journal = {
        SystemMaxUse = "500M";
        MaxFileSec = "1week";
      };
    };

    users = {
      mutableUsers = false;
      users.grey = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = ["networkmanager" "wheel"];
        hashedPasswordFile = "/persistent/passwords/grey";
      };
    };

    systemd.oomd = {
      enableSystemSlice = true;
      enableUserSlices = true;
    };

    zramSwap.enable = true;
    boot.kernel.sysctl = {
      "vm.swappiness" = 100;
      "vm.page-cluster" = 0;
    };

    security = {
      polkit.enable = true;
      sudo.wheelNeedsPassword = false;
    };

    hardware = {
      enableRedistributableFirmware = true;
    };
  };
}
