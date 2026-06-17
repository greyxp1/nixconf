{inputs, ...}: {
  flake.nixosModules.nsticky = {pkgs, ...}: let
    nsticky = inputs.nsticky.packages.${pkgs.stdenv.hostPlatform.system}.nsticky;
  in {
    home-manager.sharedModules = [
      {
        home.packages = [
          nsticky
          (pkgs.writeScriptBin "nsticky-stage-toggle" ''
            #!${pkgs.dash}/bin/dash
            STATE=/tmp/nsticky-staged
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
          [sticky.niri-pin]
          title = "^Niri-Pin-Surface$"
        '';

        systemd.user.services.nsticky = {
          Unit.Description = "nsticky sticky window manager";
          Unit.After = ["graphical-session.target"];
          Unit.PartOf = ["graphical-session.target"];
          Service.ExecStart = "${nsticky}/bin/nsticky";
          Service.Restart = "on-failure";
          Install.WantedBy = ["graphical-session.target"];
        };

        wayland.windowManager.niri.settings.binds = let
          bind = action: {_props.repeat = false;} // action;
        in {
          "Mod+G" = bind {spawn-sh = "nsticky sticky toggle-active";};
          "Mod+Shift+G" = bind {spawn = "nsticky-stage-toggle";};
        };
      }
    ];
  };
}
