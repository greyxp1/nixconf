_: {
  flake.nixosModules.mpv-pin-image = {pkgs, ...}: let
    inputConf = pkgs.writeText "mpv-pin-input.conf" ''
      WHEEL_UP add window-scale  0.05
      WHEEL_DOWN add window-scale -0.05
      Shift+WHEEL_UP add window-scale  0.01
      Shift+WHEEL_DOWN add window-scale -0.01
      MBTN_RIGHT quit
    '';
  in {
    home-manager.sharedModules = [{
      home.packages = [
        (pkgs.writeScriptBin "mpv-pin-image" ''
          #!${pkgs.dash}/bin/dash
          set -eu
          TITLE="$1"
          shift
          exec ${pkgs.mpv}/bin/mpv \
            --no-config --load-scripts=no --no-border --osc=no --osd-level=0 \
            --ao=null --sub-auto=no \
            --vo=gpu --gpu-api=opengl --keepaspect=no \
            --autofit-larger=100%x100% \
            --keep-open=yes --image-display-duration=inf \
            --input-conf="${inputConf}" \
            --title="$TITLE" \
            "$@"
        '')
      ];
    }];
  };
}
