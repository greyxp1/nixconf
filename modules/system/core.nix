{inputs, ...}: {
  flake.nixosModules.core = {config, ...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];
    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    systemd.network.wait-online.enable = false;
    services.flatpak.enable = true;

    users.users = {
      root.initialHashedPassword = "";
      grey = {
        isNormalUser = true;
        extraGroups = ["networkmanager" "wheel" "input" "seat"];
        initialPassword = "123";
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

    nix.settings = {
      trusted-users = ["root" "@wheel"];
      experimental-features = ["nix-command" "flakes"];
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      overwriteBackup = true;
      users.grey = {pkgs, ...}: {
        xdg.enable = true;
        home = {
          username = "grey";
          homeDirectory = "/home/grey";
          stateVersion = "26.05";
          packages = with pkgs; [
            inputs.helium.packages.${stdenv.hostPlatform.system}.default
            inputs.waytator.packages.${stdenv.hostPlatform.system}.default
            parsec-bin
          ];
        };
      };
    };
  };
}
