{...}: {
  flake.nixosModules.niri-pin = {pkgs, ...}: let
    mpvInputConf = pkgs.writeText "input-pin.conf" ''
      WHEEL_UP add window-scale 0.05
      WHEEL_DOWN add window-scale -0.05
      Shift+WHEEL_UP add window-scale 0.01
      Shift+WHEEL_DOWN add window-scale -0.01
      MBTN_LEFT_DBL ignore
      MBTN_RIGHT quit
    '';

    niri-pin-to-screen = pkgs.writeScriptBin "niri-pin-to-screen" ''
      #!${pkgs.dash}/bin/dash
      GEOMETRY=$(${pkgs.slurp}/bin/slurp -c "#ff0000ff" -b "#00000044" -w 1)
      [ -z "$GEOMETRY" ] && exit 0
      TEMP=$(${pkgs.coreutils}/bin/mktemp --tmpdir niri-pin-XXXXXX.png)
      ${pkgs.grim}/bin/grim -g "$GEOMETRY" "$TEMP"
      ${pkgs.util-linux}/bin/setsid ${pkgs.mpv}/bin/mpv \
        --no-config \
        --no-border \
        --osc=no \
        --osd-level=0 \
        --ao=null \
        --sub-auto=no \
        --vo=wlshm \
        --autofit-larger=100%x100% \
        --keep-open=yes \
        --image-display-duration=inf \
        --input-conf="${mpvInputConf}" \
        --title=Niri-Pin-Surface \
        "$TEMP" >/dev/null 2>&1 &
      ( ${pkgs.coreutils}/bin/sleep 2 && rm -f "$TEMP" ) &
    '';
  in {
    home-manager.sharedModules = [
      {
        home.packages = [niri-pin-to-screen];
        wayland.windowManager.niri.settings = {
          window-rule = [
            {
              match._props.title = "^Niri-Pin-Surface$";
              open-floating = true;
              border.off = {};
              focus-ring.off = {};
              clip-to-geometry = true;
            }
          ];

          binds = let
            bind = action: {_props.repeat = false;} // action;
          in {
            "Shift+Print" = bind {spawn = "niri-pin-to-screen";};
          };
        };
      }
    ];
  };
}
