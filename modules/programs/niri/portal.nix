{inputs, ...}: let
  output = "DP-2";
  width = 2560;
  height = 1440;
in {
  flake.nixosModules.niri-portal = {pkgs, ...}: {
    imports = [inputs.niri-autoselect-portal.nixosModules.default];
    services.niri-autoselect-portal = {
      enable = true;
      package = inputs.niri-autoselect-portal.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        postPatch = (old.postPatch or "")
        + ''
          substituteInPlace main.go \
            --replace-fail 'sessionObj.Call(mutterSessionInterface+".RecordWindow", 0,' 'sessionObj.Call(mutterSessionInterface+".RecordMonitor", 0,' \
            --replace-fail 'windowOptions).Store(&streamPath)' '"${output}", windowOptions).Store(&streamPath)' \
            --replace-fail '"size":        dbus.MakeVariant(size{0, 0}),' '"size":        dbus.MakeVariant(size{${toString width}, ${toString height}}),' \
            --replace-fail '"source_type": dbus.MakeVariant(uint32(2)), // WINDOW = 2' '"source_type": dbus.MakeVariant(uint32(1)), // MONITOR = 1'
        '';
      });
    };
  };
}
