{
  inputs,
  lib,
  pkgs,
  username,
  homeDirectory,
  uid,
  ...
}: let
  t3code = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code.unwrapped;
in {
  environment.systemPackages = [t3code];
  systemd.services.t3code = {
    description = "T3 Code headless server";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    environment = {
      HOME = homeDirectory;
      PATH = lib.mkForce "/etc/profiles/per-user/${username}/bin:/run/wrappers/bin:/run/current-system/sw/bin:/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin";
      SSH_AUTH_SOCK = "/run/user/${toString uid}/ssh-agent";
      XDG_RUNTIME_DIR = "/run/user/${toString uid}";
      DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${toString uid}/bus";
    };
    serviceConfig = {
      User = username;
      WorkingDirectory = homeDirectory;
      ExecStart = "${lib.getExe t3code} serve --host 127.0.0.1 --port 3773";
      Restart = "on-failure";
      RestartSec = 5;
      KillMode = "mixed";
      UMask = "0077";
    };
  };
}
