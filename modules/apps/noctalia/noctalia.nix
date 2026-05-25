{ inputs, ... }: {
  flake.nixosModules.noctalia-v5 = { pkgs, ... }: {
    environment.systemPackages = [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    home-manager.users.grey = {
      xdg.configFile."noctalia/config.toml".source = ./config.toml;
    };
  };
}
