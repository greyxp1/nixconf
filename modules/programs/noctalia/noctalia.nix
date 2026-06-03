{inputs, ...}: {
  flake.nixosModules.noctalia = {pkgs, ...}: {
    home-manager.users.grey.xdg.configFile."noctalia/config.toml".source = ./config.toml;
    environment.systemPackages = with pkgs; [
      inputs.noctalia.packages.${stdenv.hostPlatform.system}.default
      gpu-screen-recorder
    ];
  };
}
