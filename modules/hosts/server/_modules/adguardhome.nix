{pkgs, ...}: {
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = {
      http.address = "127.0.0.1:3000";
      dns = {
        bind_hosts = ["192.168.1.2"];
        upstream_dns = [
          "https://cloudflare-dns.com/dns-query"
          "https://dns.google/dns-query"
        ];
        upstream_mode = "parallel";
        bootstrap_dns = ["1.1.1.1" "8.8.8.8"];
        cache_optimistic = true;
        # Default 20 qps is shared per /24 subnet, which would throttle the whole LAN.
        ratelimit = 0;
      };
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/multi.txt";
          name = "HaGeZi Multi NORMAL";
          id = 2;
        }
      ];
      querylog.interval = "24h";
    };
  };

  preservation.preserveAt."/persistent".directories = [
    {
      directory = "/var/lib/private/AdGuardHome";
      user = ":root";
      group = ":root";
      mode = ":0700";
    }
  ];

  systemd.services = {
    adguardhome = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.RequiresMountsFor = ["/var/lib/private/AdGuardHome"];
    };

    adguardhome-access = {
      description = "AdGuard Home HTTPS access over Tailscale";
      wantedBy = ["tailscaled.service"];
      requires = ["tailscaled.service"];
      wants = ["adguardhome.service"];
      after = ["tailscaled.service" "adguardhome.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 5;
        ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https=3000 http://127.0.0.1:3000";
        ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https=3000 off";
      };
    };
  };

  networking.firewall.interfaces.eno1 = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
}
