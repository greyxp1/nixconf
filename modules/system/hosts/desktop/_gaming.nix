{pkgs, ...}: {
  programs = {
    gamemode.enable = true;
    gamemode.settings.general.renice = 10;

    steam = {
      enable = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server hosting
    };

    gamescope = {
      enable = true;
      capSysNice = true;
      env.ENABLE_GAMESCOPE_WSI = "1"; # NVIDIA-specific
    };
  };

  home-manager.users.grey = {
    programs.mangohud = {
      enable = true;
      enableSessionWide = false;
      settings = {
        legacy_layout = false;
        gpu_stats = true;
        gpu_temp = true;
        cpu_stats = true;
        cpu_temp = true;
        fps = true;
        frametime = true;
        vulkan_driver = true;
        font_size = 20;
        background_alpha = "0.4";
      };
    };

    home.packages = with pkgs; [
      umu-launcher
      #faugus-launcher
      #(heroic.override {
      #  extraPkgs = pkgs': with pkgs'; [gamescope gamemode];
      #})
      #(lutris.override {
      #  extraPkgs = pkgs': with pkgs'; [gamescope gamemode];
      #})
    ];
  };
}
