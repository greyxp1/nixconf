{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.chaotic.nixosModules.default];
  programs.steam = {
    enable = true;
    extraCompatPackages = [pkgs.proton-cachyos];
    package = pkgs.steam.override {
      extraArgs = "-silent";
      extraEnv = {
        #STEAM_ENABLE_SHADER_CACHE_MANAGEMENT = "0";
        PROTON_ENABLE_WAYLAND = "1";
        # DirectX 9–11
        PROTON_DXVK_LOWLATENCY = "1";
        DXVK_FRAME_RATE = "160";
        DXVK_FRAME_PACE = "low-latency-vrr-167";
        # DirectX 12
        PROTON_VKD3D_LOWLATENCY = "1";
        VKD3D_FRAME_RATE = "160";
      };
    };
  };

  home-manager.sharedModules = [
    {
      programs.mangohud.enable = true;
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
            match._props."app-id" = "^steam_app_";
            open-fullscreen = true;
            variable-refresh-rate = true;
          };
        }
        {
          window-rule = {
            match._props."app-id" = "^steam$";
            open-fullscreen = false;
          };
        }
      ];
    }
  ];
}
