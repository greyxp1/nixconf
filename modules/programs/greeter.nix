{inputs, ...}: {
  flake.nixosModules.niri = {pkgs, ...}: {
    imports = [inputs.noctalia-greeter.nixosModules.default];
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        session.default = "Niri (UWSM)";
        appearance.scheme = "Synced";
      };
    };

    systemd.tmpfiles.rules = let
      appearanceJson = pkgs.writeText "noctalia-appearance.json" ''
        {
          "corner_radius_scale": 1.0,
          "palette": {
            "error": "#F38BA8",
            "hover": "#94E2D5",
            "on_error": "#11111B",
            "on_hover": "#11111B",
            "on_primary": "#11111B",
            "on_secondary": "#11111B",
            "on_surface": "#CDD6F4",
            "on_surface_variant": "#A3B4EB",
            "on_tertiary": "#11111B",
            "outline": "#44465D",
            "primary": "#CBA6F7",
            "secondary": "#FAB387",
            "shadow": "#11111B",
            "surface": "#1E1E2E",
            "surface_variant": "#313244",
            "tertiary": "#94E2D5"
          },
          "session": {
            "actions": [
              { "action": "lock" },
              { "action": "logout" },
              { "action": "lock_and_suspend" },
              { "action": "reboot" },
              { "action": "shutdown", "variant": "destructive" }
            ]
          },
          "theme_mode": "dark",
          "version": 1,
          "wallpaper": {
            "fill_mode": "crop",
            "path": "${../../assets/wallpapers/wheat.jpg}"
          }
        }
      '';
    in [
      "d /var/lib/noctalia-greeter 0755 greeter greeter -"
      "L+ /var/lib/noctalia-greeter/appearance.json - - - - ${appearanceJson}"
    ];
  };
}
