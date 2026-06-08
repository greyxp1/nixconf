{inputs, ...}: {
  flake.nixosModules.niri-autoselect-portal = {pkgs, ...}: {
    imports = [inputs.niri-autoselect-portal.nixosModules.default];
    services.niri-autoselect-portal.enable = true;
    home-manager.sharedModules = [
      {
        wayland.windowManager.niri.settings.spawn-sh-at-startup = [{_args = ["screencast-monitor"];}];
        home.packages = [
          (pkgs.writeScriptBin "screencast-monitor" ''
            #!${pkgs.dash}/bin/dash
            dbus-monitor --session "type='method_call',interface='org.freedesktop.portal.ScreenCast',member='Start'" \
            | grep --line-buffered "method call" \
            | while read -r _; do niri msg action set-dynamic-cast-monitor; done
          '')
        ];
      }
    ];
  };
}
