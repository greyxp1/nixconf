{inputs, ...}: let
  output = "DP-2";
  width = 2560;
  height = 1440;
in {
  flake.nixosModules.niri-portal = {pkgs, ...}: {
    imports = [inputs.niri-autoselect-portal.nixosModules.default];
    services.niri-autoselect-portal = {
      enable = true;
      package = inputs.niri-autoselect-portal.packages.${pkgs.system}.default.overrideAttrs (old: {
        postPatch = (old.postPatch or "")
        + ''
                  substituteInPlace main.go \
                    --replace-fail 'sessionObj.Call(mutterSessionInterface+".RecordWindow", 0,
          windowOptions).Store(&streamPath)' 'sessionObj.Call(mutterSessionInterface+".RecordMonitor", 0,
          "${output}", windowOptions).Store(&streamPath)' \
                    --replace-fail '"position":    dbus.MakeVariant(map[string]int32{"x": 0, "y": 0}),' '"position":    dbus.MakeVariant(struct{ X, Y int32 }{0, 0}),' \
                    --replace-fail '"size":        dbus.MakeVariant(map[string]int32{"width": 0, "height": 0}),' '"size":        dbus.MakeVariant(struct{ Width, Height int32 }{${toString width}, ${toString height}}),' \
                    --replace-fail '"source_type": dbus.MakeVariant(uint32(2)), // WINDOW = 2' '"source_type": dbus.MakeVariant(uint32(1)), // MONITOR = 1'
        '';
      });
    };
  };
}
