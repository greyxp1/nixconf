{lib, ...}: {
  time.timeZone = "America/Montreal";
  networking.networkmanager.enable = true;
  preservation.preserveAt."/persistent".directories = ["/var/lib/NetworkManager"];
  hardware.enableRedistributableFirmware = true;
  systemd = {
    oomd.enableSystemSlice = true;
    # Target workloads without making the desktop session an oomd candidate.
    user.slices.app.sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "50%";
      ManagedOOMMemoryPressureDurationSec = "10s";
    };
    user.slices.background.sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "50%";
      ManagedOOMMemoryPressureDurationSec = "10s";
    };
  };

  boot = {
    kernelParams = ["systemd.show_status=auto"];
    consoleLogLevel = 3;
    loader = {
      efi.canTouchEfiVariables = lib.mkDefault true;
      systemd-boot.enable = lib.mkDefault true;
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
