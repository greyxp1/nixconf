{inputs, ...}: {
  flake.nixosModules.core = {config, ...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];
    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    system.nixos.label = config.networking.hostName;
    system.stateVersion = "25.11";
    zramSwap.enable = true;
    zramSwap.algorithm = "zstd";
    systemd.network.wait-online.enable = false;
    users.users.root.initialHashedPassword = "";
    users.users.grey = {
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel" "input" "seat"];
      initialPassword = "123";
    };

    nix.settings = {
      trusted-users = ["root" "@wheel"];
      experimental-features = ["nix-command" "flakes"];
      max-jobs = "auto";
      cores = 0;
      http-connections = 128;
      download-buffer-size = 536870912;
    };

    services = {
      flatpak.enable = true;
      irqbalance.enable = true;
      dbus.enable = true;
      greetd = {
        enable = true;
        settings.default_session.command = "niri-session";
        settings.default_session.user = "grey";
      };
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
      graphics.enable32Bit = true;
    };

    security = {
      polkit.enable = true;
      sudo.wheelNeedsPassword = false;
      rtkit.enable = true;
    };

    boot = {
      supportedFilesystems = ["btrfs"];
      initrd.supportedFilesystems = ["btrfs"];
      initrd.systemd.enable = true;
      kernel.sysctl = {
        "vm.swappiness" = 100;
        "vm.page-cluster" = 0;
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        "net.core.netdev_max_backlog" = 16384;
      };
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
        timeout = 0;
      };
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      overwriteBackup = true;
      sharedModules = [inputs.catppuccin.homeModules.catppuccin];
      users.grey = {pkgs, ...}: {
        xdg.enable = true;
        home = {
          username = "grey";
          homeDirectory = "/home/grey";
          stateVersion = "26.05";
          packages = [
            inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
            pkgs.parsec-bin
          ];
        };
      };
    };
  };
}
