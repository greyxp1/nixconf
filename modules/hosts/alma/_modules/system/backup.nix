{...}: {
  alma.packages = ["python3-libvirt" "qemu-img" "rsync"];
  alma.services = ["branch3-backup.timer"];
  environment.etc = {
    "branch3-backup/backup.py".source = ./branch3-backup.py;
    "systemd/system/branch3-backup.service" = {
      replaceExisting = true;
      text = ''
        [Unit]
        Description=Branch 3 backups to either Proxmox backup disk host
        After=network-online.target virtqemud.service
        Wants=network-online.target
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/python3 /etc/branch3-backup/backup.py
        TimeoutStartSec=6h
        TimeoutStopSec=120
        Nice=10
        IOSchedulingClass=best-effort
        IOSchedulingPriority=7
        UMask=0077
      '';
    };
    "systemd/system/branch3-backup.timer" = {
      replaceExisting = true;
      text = ''
        [Unit]
        Description=Back up branch 3 daily when the project disk is connected
        [Timer]
        OnBootSec=5min
        OnUnitActiveSec=5min
        Unit=branch3-backup.service
        [Install]
        WantedBy=timers.target
      '';
    };
  };
}
