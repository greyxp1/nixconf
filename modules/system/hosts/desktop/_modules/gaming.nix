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

  environment.systemPackages = with pkgs; [pandora-launcher heroic];
  wrappers.niri.settings = {
    outputs.DP-2 = {
      mode = "2560x1440@170.071";
      variable-refresh-rate = _: {props.on-demand = true;};
    };
    window-rules = [
      {
        matches = [{"app-id" = "(?i)^steam_app_|^terraria|^minecraft$";}];
        open-fullscreen = true;
        open-on-workspace = "default";
        variable-refresh-rate = true;
      }
      {
        matches = [{"app-id" = "^steam$";}];
        open-fullscreen = false;
        open-on-workspace = "default";
      }
      {
        matches = [{title = "^(Sign in to Steam|Shutdown)$";}];
        open-on-workspace = "default";
      }
      {
        matches = [{"app-id" = ''^notificationtoasts_\d+_desktop$'';}];
        open-floating = true;
        default-floating-position = _: {
          props = {
            relative-to = "bottom-right";
            x = 12;
            y = 12;
          };
        };
      }
    ];
  };
}
