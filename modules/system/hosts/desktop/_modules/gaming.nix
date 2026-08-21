{pkgs, ...}: {
  programs.steam = {
    enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
    package = pkgs.steam.override {
      #extraArgs = "-silent";
      extraEnv = {
        #STEAM_ENABLE_SHADER_CACHE_MANAGEMENT = "0";
        PROTON_ENABLE_WAYLAND = "1";
        DXVK_CONFIG = "dxvk.latencySleep = True; dxgi.maxFrameRate = 167; d3d9.maxFrameRate = 167";
        VKD3D_FRAME_RATE = "167";
      };
    };
  };

  home-manager.sharedModules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [pandora-launcher heroic];
      wayland.windowManager.niri.settings._children = [
        {
          output = {
            _args = ["DP-2"];
            mode = "2560x1440@170.071";
            variable-refresh-rate._props.on-demand = true;
          };
        }
        {
          window-rule = {
            match._props."app-id" = "^steam_app_|^Terraria.bin.x86_64$|^Minecraft";
            open-fullscreen = true;
            open-on-workspace = "default";
            variable-refresh-rate = true;
          };
        }
        {
          window-rule = {
            match._props."app-id" = "^steam$";
            open-fullscreen = false;
            open-on-workspace = "default";
          };
        }
        {
          window-rule = {
            match._props.title = "^(Sign in to Steam|Shutdown)$";
            open-on-workspace = "default";
          };
        }
        {
          window-rule = {
            match._props."app-id" = ''^notificationtoasts_\d+_desktop$'';
            open-floating = true;
            default-floating-position._props = {
              relative-to = "bottom-right";
              x = 12;
              y = 12;
            };
          };
        }
      ];
    })
  ];
}
