{
  inputs,
  lib,
  pkgs,
  ...
}: let
  rex = inputs.rex.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  environment.systemPackages = [rex];

  systemd.user.services.rex = {
    description = "Personal Rex server";
    wantedBy = ["default.target"];
    restartIfChanged = false;
    # Terminals need the user manager's login PATH, including profile commands.
    enableDefaultPath = false;
    environment.TERMINFO_DIRS = "${rex}/share/terminfo:/run/current-system/sw/share/terminfo";
    serviceConfig = {
      Type = "notify";
      ExecStart = "${lib.getExe' rex "rex"} server run --extra-listen tailnet://:7297";
      Restart = "always";
      RestartSec = "1s";
      KillMode = "mixed";
    };
  };
}
