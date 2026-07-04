{
  flake.nixosModules.core = {config, pkgs, ...}: {
    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    systemd.network.wait-online.enable = false;
    services.flatpak.enable = true;
    services.journald.extraConfig = "SystemMaxUse=500M\nMaxFileSec=1week";
    programs.nix-ld.enable = true;

    users.users = {
      root.initialHashedPassword = "";
      grey = {
        isNormalUser = true;
        extraGroups = ["networkmanager" "wheel" "input" "seat"];
      };
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    system = {
      nixos.label = config.networking.hostName;
      stateVersion = "26.05";
    };

    security = {
      polkit.enable = true;
      sudo.wheelNeedsPassword = false;
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
