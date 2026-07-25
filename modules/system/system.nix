{
  flake.nixosModules.system = {username, ...}: {
    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;

    services = {
      irqbalance.enable = true;
      journald.extraConfig = "SystemMaxUse=500M\nMaxFileSec=1week";
      pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
      };
    };

    users = {
      mutableUsers = false;
      users.${username} = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = ["networkmanager" "wheel"];
        hashedPasswordFile = "/persistent/passwords/${username}";
      };
    };

    zramSwap.enable = true;
    boot.kernel.sysctl = {
      "vm.swappiness" = 100;
      "vm.page-cluster" = 0;
    };

    security = {
      polkit.enable = true;
      rtkit.enable = true;
      sudo.wheelNeedsPassword = false;
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
    };
  };
}
