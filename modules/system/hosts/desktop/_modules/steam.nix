{pkgs, ...}: {
  home-manager.users.grey.programs.mangohud.enable = true;
  programs.steam = {
    enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
    package = pkgs.steam.override {extraEnv.PROTON_ENABLE_WAYLAND = "1";};
  };
}
