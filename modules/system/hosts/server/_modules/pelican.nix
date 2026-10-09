{pkgs, ...}: let
  wings = pkgs.stdenvNoCC.mkDerivation {
    pname = "pelican-wings";
    version = "1.0.0-beta29";
    src = pkgs.fetchurl {
      url = "https://github.com/pelican/wings/releases/download/v1.0.0-beta29/wings_linux_amd64";
      sha256 = "75d81ecf25366ed3c05ad6c6ccbad532ed896b8219aa9d2c93a5af003d69000b";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 "$src" "$out/bin/pelican-wings"
    '';
  };
  caddyConfig = pkgs.writeText "pelican-Caddyfile" ''
    {
      admin off
      auto_https off
    }
    http://:18080 {
      bind 127.0.0.1
      root * /var/www/html/public
      encode gzip
      file_server
      php_fastcgi 127.0.0.1:9000
    }
  '';
in {
  virtualisation.oci-containers.containers.pelican = {
    image = "ghcr.io/pelican/panel@sha256:46f356f3fda423b1d43f0dc3c71efc056cd8b9bec365d1d7817306a17ee5694a";
    extraOptions = ["--network=host" "--add-host=server.tail1785c.ts.net:100.72.114.84"];
    volumes = [
      "/home/grey/.local/share/pelican:/pelican-data"
      "${caddyConfig}:/etc/caddy/Caddyfile:ro"
      "${./pelican-backup.php}:/opt/pelican-backup.php:ro"
    ];
    environment = {
      APP_URL = "https://server.tail1785c.ts.net:8444";
      BEHIND_PROXY = "true";
      TRUSTED_PROXIES = "127.0.0.1";
      TZ = "America/Montreal";
      DB_CONNECTION = "sqlite";
      CACHE_STORE = "file";
      QUEUE_CONNECTION = "database";
      SESSION_DRIVER = "file";
    };
  };
  systemd.tmpfiles.rules = [
    "d /home/grey/.local/share/pelican 0700 82 82 -"
    "d /home/grey/Games/Pelican 0750 grey users -"
    "d /home/grey/Backups/Games 0750 grey users -"
    "d /persistent/secrets/pelican 0700 root root -"
    "d /var/log/pelican 0750 root root -"
  ];
  systemd.services.docker-pelican = {
    requires = ["preservation.target"];
    after = ["preservation.target"];
    unitConfig.RequiresMountsFor = ["/home/grey/.local/share/pelican"];
  };
  systemd.services.pelican-wings = {
    description = "Pelican game server daemon";
    wantedBy = ["multi-user.target"];
    requires = ["docker.service" "preservation.target"];
    after = ["docker.service" "preservation.target" "network-online.target"];
    wants = ["network-online.target"];
    path = [pkgs.shadow pkgs.iproute2];
    unitConfig = {
      ConditionPathExists = "/persistent/secrets/pelican/config.yml";
      RequiresMountsFor = ["/home/grey/Games/Pelican" "/home/grey/Backups/Games"];
    };
    serviceConfig = {
      ExecStart = "${wings}/bin/pelican-wings --config /persistent/secrets/pelican/config.yml";
      Restart = "on-failure";
      RestartSec = 5;
      LimitNOFILE = 65536;
    };
  };
  systemd.services.pelican-access = {
    description = "Pelican HTTPS access over Tailscale";
    wantedBy = ["multi-user.target"];
    requires = ["tailscaled.service"];
    after = ["tailscaled.service" "network-online.target"];
    wants = ["network-online.target"];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      ${pkgs.tailscale}/bin/tailscale serve --bg --https=8444 http://127.0.0.1:18080
      ${pkgs.tailscale}/bin/tailscale serve --bg --https=8445 http://127.0.0.1:18081
    '';
  };
  systemd.services.pelican-backup = {
    description = "Back up Pelican games and rotate old backups";
    requires = ["docker-pelican.service" "pelican-wings.service"];
    after = ["docker-pelican.service" "pelican-wings.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.docker}/bin/docker exec pelican php /opt/pelican-backup.php";
      TimeoutStartSec = "2h";
      ExecStartPost = "${pkgs.coreutils}/bin/chown -R grey:users /home/grey/Backups/Games";
    };
  };
  systemd.timers.pelican-backup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00";
      Persistent = true;
    };
  };
  networking.firewall.allowedTCPPorts = [25565];
}
