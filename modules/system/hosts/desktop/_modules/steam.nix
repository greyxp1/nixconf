{pkgs, ...}: {
  home-manager.users.grey.programs.mangohud.enable = true;
  programs.steam = {
    enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
  };
}
