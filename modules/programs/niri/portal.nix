{inputs, ...}: {
  flake.nixosModules.niri-autoselect-portal = {pkgs, ...}: let
    screencastMonitor = pkgs.writeScript "screencast-monitor" ''
      #!${pkgs.dash}/bin/dash
      dbus-monitor --session \
        "type='method_call',interface='org.freedesktop.portal.ScreenCast',member='Start'" \
      | grep --line-buffered "method call" \
      | while IFS= read -r _; do
          niri msg action set-dynamic-cast-monitor
        done
    '';
  in {
    imports = [inputs.niri-autoselect-portal.nixosModules.default];
    services.niri-autoselect-portal.enable = true;
    home-manager.sharedModules = [
      {
        systemd.user.services.screencast-monitor = {
          Unit.Description = "Auto-set niri dynamic cast target on screenshare";
          Unit.After = ["graphical-session.target"];
          Unit.PartOf = ["graphical-session.target"];
          Service.ExecStart = "${screencastMonitor}";
          Service.Restart = "on-failure";
          Install.WantedBy = ["graphical-session.target"];
        };
      }
    ];
  };
}
