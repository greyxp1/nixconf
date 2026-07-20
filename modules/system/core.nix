{
  flake.nixosModules.core = {config, pkgs, ...}: {
    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    programs.nix-ld.enable = true;
    services.irqbalance.enable = true;
    services.journald.extraConfig = "SystemMaxUse=500M\nMaxFileSec=1week";

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
    };

    users = {
      mutableUsers = false;
      users = {
        grey = {
          isNormalUser = true;
          extraGroups = ["networkmanager" "wheel"];
          hashedPassword = "$y$j9T$Z9Tz04i5gNbpCTQRko1Tl/$4DLXu5Eb3zvlRPWFxFsiFTYmjylQRWguIu8fYkld.r7";
        };
      };
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
    };

    security = {
      polkit.enable = true;
      rtkit.enable = true;
      sudo.wheelNeedsPassword = false;
    };

    system = {
      nixos.label = config.networking.hostName;
      stateVersion = "26.05";
    };

    zramSwap.enable = true;
    boot.kernel.sysctl = {
      "vm.swappiness" = 100;
      "vm.page-cluster" = 0;
    };

    nix = {
      package = pkgs.lix;
      settings = {
        trusted-users = ["@wheel"];
        experimental-features = ["nix-command" "flakes"];
        warn-dirty = false;
      } // import ./_cache.nix;
    };
  };
}
