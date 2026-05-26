{ inputs, ... }: {
  flake.nixosModules.core = { config, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];

    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;
    nixpkgs.config.allowUnfree = true;
    security.polkit.enable = true;
    documentation.nixos.enable = false;

    system = {
      nixos.label = config.networking.hostName;
      stateVersion = "25.11";
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };

    users.users = {
      root.initialHashedPassword = "";
      grey = {
        isNormalUser = true;
        extraGroups = [ "networkmanager" "wheel" "input" "seat" ];
        initialPassword = "123";
      };
    };

    nix.settings = {
      trusted-users = [ "root" "@wheel" ];
      experimental-features = [ "nix-command" "flakes" ];
    };

    services = {
      greetd = {
        enable = true;
        useTextGreeter = true;
        restart = false;
        settings.default_session = {
          command = "niri-session";
          user = "grey";
        };
      };
      upower.enable = true;
      power-profiles-daemon.enable = true;
      dbus.enable = true;
      gvfs.enable = true;
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
  };
}
