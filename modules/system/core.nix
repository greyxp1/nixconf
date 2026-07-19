{
  flake.nixosModules.core = {config, pkgs, ...}: {
    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    systemd.network.wait-online.enable = false;
    programs.nix-ld.enable = true;
    services.flatpak.enable = true;
    services.journald.extraConfig = "SystemMaxUse=500M\nMaxFileSec=1week";

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
    };

    users = {
      mutableUsers = false;
      users = {
        grey = {
          isNormalUser = true;
          extraGroups = ["networkmanager" "wheel" "input" "seat"];
          hashedPassword = "$y$j9T$Z9Tz04i5gNbpCTQRko1Tl/$4DLXu5Eb3zvlRPWFxFsiFTYmjylQRWguIu8fYkld.r7";
        };
      };
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
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

    nix = {
      package = pkgs.lix;
      settings = {
        trusted-users = ["@wheel"];
        experimental-features = ["nix-command" "flakes"];
        warn-dirty = false;
        auto-optimise-store = true;
        min-free = 536870912;
      } // import ./_cache.nix;
    };
  };
}
