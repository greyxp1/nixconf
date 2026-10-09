{lib, ...}: {
  flake.nixosModules.sshfs = {
    config,
    pkgs,
    utils,
    ...
  }: {
    environment.systemPackages = [pkgs.sshfs];
    systemd.tmpfiles.rules = lib.mkIf (config.networking.hostName == "desktop") [
      "d /home/server 0700 grey users -"
    ];
    systemd.user.services.server-files = lib.mkIf (config.networking.hostName == "desktop") {
      description = "Server home folder";
      wantedBy = ["default.target"];
      unitConfig.ConditionUser = "grey";
      serviceConfig = {
        Type = "exec";
        ExecStart = utils.escapeSystemdExecArgs [
          "${pkgs.sshfs}/bin/sshfs"
          "-f"
          "grey@server.tail1785c.ts.net:/home/grey"
          "/home/server"
          "-o"
          "reconnect,auto_unmount,ServerAliveInterval=15,ServerAliveCountMax=3,ConnectTimeout=10,BatchMode=yes,IdentityFile=/home/grey/.ssh/id_ed25519"
        ];
        ExecStop = "/run/wrappers/bin/fusermount3 -u /home/server";
        Restart = "on-failure";
        RestartSec = "15s";
        TimeoutStopSec = "10s";
      };
    };
    wrappers.yazi.settings.keymap.mgr.prepend_keymap = lib.mkIf (config.networking.hostName == "desktop") [
      {
        on = ["g" "s"];
        run = "cd /home/server";
        desc = "Go to server home";
      }
    ];
  };
}
