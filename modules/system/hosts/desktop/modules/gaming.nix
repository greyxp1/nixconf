{config, ...}: let flakeConfig = config; in {
  flake.nixosModules.gaming = {config, lib, pkgs, ...}: {
    options.custom.gaming.enable = lib.mkEnableOption "gaming setup";
    config = lib.mkIf config.custom.gaming.enable {
      home-manager.users.grey.imports = [flakeConfig.flake.homeProfiles.gaming];
      programs = {
        steam = {
          enable = true;
          extraCompatPackages = [pkgs.proton-ge-bin];
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
        };

        gamescope = {
          enable = true;
          capSysNice = true;
          env.ENABLE_GAMESCOPE_WSI = "1";
        };

        gamemode = {
          enable = true;
          settings.general.renice = 10;
        };
      };
    };
  };

  flake.homeProfiles.gaming = {pkgs, ...}: {
    home.packages = [pkgs.umu-launcher];
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
  };
}
