{inputs, ...}: {
  flake.nixosModules.nsticky = {pkgs, ...}: {
    home-manager.sharedModules = [
      {
        home.packages = [
          inputs.nsticky.packages.${pkgs.stdenv.hostPlatform.system}.nsticky

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

        wayland.windowManager.niri.settings = {
          spawn-at-startup = [
            {_args = ["nsticky"];}
          ];
          binds = let
            bind = action: {_props.repeat = false;} // action;
          in {
            "Mod+G" = bind {spawn-sh = "nsticky sticky toggle-active";};
            "Mod+Shift+G" = bind {spawn-sh = "nsticky-stage-toggle";};
          };
        };
      }
    ];
  };
}
