{pkgs, ...}: {
  home-manager.sharedModules = [
    {
      programs.mangohud.enable = true;

      wayland.windowManager.niri.settings = {
        spawn-at-startup = [{_args = ["steam" "-silent"];}];
        output = [
          {
            _args = ["DP-2"];
            mode = "2560x1440@170.071";
            variable-refresh-rate._props.on-demand = true;
          }
        ];
        window-rule = [
          {
            match._props."app-id" = "^steam_app_";
            open-fullscreen = true;
            variable-refresh-rate = true;
          }
          {
            match._props."app-id" = "^steam$";
            open-fullscreen = false;
          }
        ];
      };
    }
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
    package = pkgs.steam.override {extraEnv.PROTON_ENABLE_WAYLAND = "1";};
  };
}
