{
  inputs,
  lib,
  pkgs,
  ...
}: let
  sunshine = inputs.self.sunshinePackage;
  hostSunshine = pkgs.replaceDirectDependencies {
    drv = sunshine;
    replacements = [
      {
        oldDependency = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux.glibc;
        newDependency = pkgs.glibc;
      }
    ];
  };
  display = inputs.self.sunshineDisplay pkgs;
  prepCommands = builtins.toJSON [
    {
      do = "${lib.getExe display} start";
      undo = "${lib.getExe display} restore";
    }
  ];
  sessionService = command: {
    Unit = {
      After = "graphical-session.target";
      PartOf = "graphical-session.target";
    };
    Service = {
      ExecStart = command;
      Restart = "on-failure";
    };
    Install.WantedBy = "graphical-session.target";
  };
in {
  environment.etc."modules-load.d/uinput.conf".text = "uinput\nuhid\n";
  environment.etc."udev/rules.d/85-sunshine-input.rules".text = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input", TAG+="seat", TAG+="uaccess", OPTIONS+="static_node=uinput"
    KERNEL=="uhid", SUBSYSTEM=="misc", MODE="0660", GROUP="input", TAG+="seat", TAG+="uaccess", OPTIONS+="static_node=uhid"
  '';
  imports = [
    (import ./_userServices.nix {
      "app-dev.lizardbyte.app.Sunshine" = lib.recursiveUpdate (sessionService (lib.escapeShellArgs [
        "${hostSunshine}/bin/sunshine"
        "hevc_mode=1"
        "csrf_allowed_origins=https://alma.tail1785c.ts.net:47990"
        "vaapi_quality=balanced"
        "qp=20"
        "global_prep_cmd=${prepCommands}"
      ])) {Service.ExecStopPost = "-${lib.getExe display} restore";};
    })
  ];
  environment.systemPackages = [hostSunshine];
}
