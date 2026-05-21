{ inputs, ... }:
{
  flake.nixosModules.niri =
    { pkgs, ... }:

    let
      oniri = pkgs.rustPlatform.buildRustPackage {
        pname = "oniri";
        version = "0-unstable";
        src = inputs.oniri;
        cargoHash = "sha256-ue08WszHwDbnXRR3lxcwCrtC2XMpg55BXcj65tS3u1E=";
      };
    in
    {
      imports = [
        inputs.niri.nixosModules.niri
        inputs.niri-autoselect-portal.nixosModules.default
      ];

      programs.niri = {
        enable = true;
        package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
      };

      services.niri-autoselect-portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-termfilechooser ];
      xdg.portal.config.niri."org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];

      home-manager.sharedModules = [
        {
          programs.niri.config = builtins.readFile ./config.kdl;
          home.packages = [
            pkgs.xwayland-satellite
            oniri
            inputs.nsticky.packages.${pkgs.stdenv.hostPlatform.system}.nsticky

            (pkgs.writeScriptBin "screencast-monitor" ''
              #!${pkgs.dash}/bin/dash
              dbus-monitor --session "type='method_call',interface='org.freedesktop.portal.ScreenCast',member='Start'" \
              | grep --line-buffered "method call" \
              | while read -r _; do niri msg action set-dynamic-cast-monitor; done
            '')

            (pkgs.writeScriptBin "nsticky-stage-toggle" ''
              #!${pkgs.dash}/bin/dash
              STATE="/tmp/nsticky-staged"
              if [ -f "$STATE" ]; then
                nsticky stage remove-all && rm "$STATE"
              else
                nsticky stage add-all && touch "$STATE"
              fi
            '')
          ];

          xdg.configFile."nsticky/config.toml".text = ''
            [sticky.pip]
            title = "^Picture in picture$"

            [sticky.chrome-pip]
            app_id = "^chrome-ldgfbffkinooeloadekpmfoklnobpien-Default$"

            [sticky.discord-vc]
            app_id = "^discord$"
            title = "^VC[^|]*$"
          '';

          xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
            [filechooser]
            cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
            default_dir=$HOME
            env=TERMCMD=kitty --class yazi-filepicker
          '';
        }
      ];
    };
}
