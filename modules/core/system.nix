{config, ...}: {
  time.timeZone = "America/Montreal";
  networking.networkmanager.enable = true;
  preservation.preserveAt."/persistent".directories = ["/var/lib/NetworkManager"];
  hardware.enableRedistributableFirmware = true;

  systemd = {
    services.systemd-oomd.restartTriggers = [config.environment.etc."systemd/oomd.conf".source];
    oomd.enableSystemSlice = true;
    user.slices = {
      app.sliceConfig = {
        ManagedOOMSwap = "kill";
        ManagedOOMMemoryPressure = "kill";
      };

      background.sliceConfig = {
        ManagedOOMSwap = "kill";
        ManagedOOMMemoryPressure = "kill";
      };
    };

    slices = {
      # Use the shared oomd default instead of NixOS's system.slice override.
      system.sliceConfig.ManagedOOMMemoryPressureLimit = "0%";
      user.sliceConfig.MemoryLow = "25%";
    };
  };

  boot = {
    kernelParams = ["systemd.show_status=auto"];
    consoleLogLevel = 3;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
      timeout = 0;
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

  services = {
    irqbalance.enable = true;
    journald.settings.Journal = {
      SystemMaxUse = "500M";
      MaxFileSec = "1week";
    };
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
}
