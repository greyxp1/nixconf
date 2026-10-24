{
  pkgs,
  utils,
  ...
}: let
  serverSftp = pkgs.writeShellScript "server-sftp" ''
    exec ${pkgs.tailscale}/bin/tailscale ssh grey@server -oBatchMode=yes -oConnectTimeout=10 -oServerAliveInterval=15 -oServerAliveCountMax=3 -s sftp
  '';
in {
  environment.systemPackages = [pkgs.sshfs];
  systemd.tmpfiles.rules = [
    "d /home/server 0700 grey users -"
  ];
  systemd.user.services.server-files = {
    description = "Server home folder";
    wantedBy = ["default.target"];
    unitConfig.ConditionUser = "grey";
    path = [pkgs.openssh];
    serviceConfig = {
      Type = "exec";
      ExecStart = utils.escapeSystemdExecArgs [
        "${pkgs.sshfs}/bin/sshfs"
        "-f"
        "grey@server:/home/grey"
        "/home/server"
        "-o"
        "reconnect,auto_unmount,ssh_command=${serverSftp}"
      ];
      ExecStop = "/run/wrappers/bin/fusermount3 -u /home/server";
      Restart = "on-failure";
      RestartSec = "15s";
      TimeoutStopSec = "10s";
    };
  };
  programs.yazi.settings.keymap.mgr.prepend_keymap = [
    {
      on = ["g" "s"];
      run = "cd /home/server";
      desc = "Go to server home";
    }
  ];
}
