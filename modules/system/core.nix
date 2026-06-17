{inputs, ...}: {
  flake.nixosModules.core = {config, ...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];
    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    system.nixos.label = config.networking.hostName;
    system.stateVersion = "25.11";
    systemd.network.wait-online.enable = false;
    security.polkit.enable = true;
    security.sudo.wheelNeedsPassword = false;
    services.flatpak.enable = true;
    nix.settings.trusted-users = ["root" "@wheel"];
    nix.settings.experimental-features = ["nix-command" "flakes"];
    users.users.root.initialHashedPassword = "";
    users.users.grey = {
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel" "input" "seat"];
      initialPassword = "123";
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
      graphics.enable32Bit = true;
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
