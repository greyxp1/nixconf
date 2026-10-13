{
  inputs,
  lib,
  config,
  pkgs,
  utils,
  ...
}: let
  display = inputs.self.mkSunshineDisplay pkgs;
  prepCommands = builtins.toJSON [
    {
      do = "${lib.getExe display} start";
      undo = "${lib.getExe display} restore";
    }
  ];
in {
  services.sunshine.package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.sunshine-cuda;
  environment.systemPackages = [display];
  systemd.user.services.sunshine = {
    environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    serviceConfig = {
      ExecStart = lib.mkOverride 40 (utils.escapeSystemdExecArgs [
        (lib.getExe config.services.sunshine.package)
        "csrf_allowed_origins=https://${config.networking.hostName}.tail1785c.ts.net:47990"
        "global_prep_cmd=${prepCommands}"
      ]);
      ExecStopPost = "-${lib.getExe display} restore";
    };
  };
}
