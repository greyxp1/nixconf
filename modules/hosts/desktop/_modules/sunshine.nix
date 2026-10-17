{
  lib,
  config,
  pkgs,
  utils,
  ...
}: let
  display = import ../../../desktop/_sunshine-display.nix {inherit pkgs;};
  prepCommands = builtins.toJSON [
    {
      do = "${lib.getExe display} start";
      undo = "${lib.getExe display} restore";
    }
  ];
in {
  services.sunshine.cudaSupport = true;
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
