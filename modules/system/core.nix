{ inputs, ... }: {
  flake.nixosModules.core = { config, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];
    time.timeZone = "America/Montreal";
    networking.networkmanager.enable = true;
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    security.polkit.enable = true;
    security.sudo.wheelNeedsPassword = false;
    system.nixos.label = config.networking.hostName;
    system.stateVersion = "25.11";
    zramSwap.enable = true;
    zramSwap.algorithm = "zstd";
    nix.settings.trusted-users = [ "root" "@wheel" ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    services = {
      upower.enable = true;
      power-profiles-daemon.enable = true;
      dbus.enable = true;
      gvfs.enable = true;
      greetd = {
        enable = true;
        useTextGreeter = true;
        restart = false;
        settings.default_session.command = "niri-session";
        settings.default_session.user = "grey";
      };
    };

    users.users.root.initialHashedPassword = "";
    users.users.grey = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "input" "seat" ];
      initialPassword = "123";
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
      graphics.enable32Bit = true;
    };
  };
}
