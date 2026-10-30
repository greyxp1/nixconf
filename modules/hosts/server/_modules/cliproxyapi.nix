{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  services.cliproxyapi = {
    enable = true;
    package = inputs.cliproxyapi.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      config-version = 8;
      server = {
        host = "127.0.0.1";
        trusted-proxies = ["127.0.0.1" "::1"];
      };
      management = {
        allow-remote = true;
        disable-control-panel = true;
        secret-key._secret = "/persistent/secrets/cliproxyapi/management-key";
      };
      pool = {
        enabled = true;
        address = "127.0.0.1:8318";
        origin = "https://greyxp1.root.sx";
        clients-file = "/var/lib/cliproxyapi/clients.json";
        database = "/var/lib/cliproxyapi/pool.sqlite";
        maintenance = true;
      };
      routing = {
        strategy = "quota-pressure";
        session-affinity = true;
        # Retries are off unless set. These match Theo's proxy guide.
        retry = {
          request-retry = 3;
          max-retry-interval = 30;
        };
      };
      oauth.auth-dir = "/var/lib/cliproxyapi/auth";
    };
  };

  environment.systemPackages = [config.services.cliproxyapi.package];

  preservation.preserveAt."/persistent".directories = [
    {
      directory = "/var/lib/cliproxyapi";
      user = "cliproxyapi";
      group = "cliproxyapi";
      mode = "0700";
    }
  ];

  # Every client stops if the hub sleeps.
  systemd.targets = lib.genAttrs ["sleep" "suspend" "hibernate" "hybrid-sleep"] (_: {enable = false;});

  systemd.services.cliproxyapi = {
    requires = ["preservation.target"];
    after = ["preservation.target"];
    unitConfig.RequiresMountsFor = ["/var/lib/cliproxyapi"];
  };

  services.caddy.virtualHosts."greyxp1.root.sx".extraConfig = lib.mkBefore ''
    @proxy path /v1/models /v1/models/* /v1/messages /v1/messages/count_tokens /v1/chat/completions /v1/completions /v1/responses /v1/responses/compact /v1/alpha/search /responses /responses/compact
    handle @proxy {
      route {
        forward_auth 127.0.0.1:8318 {
          uri /authorize
          copy_headers Authorization
        }
        request_header -X-Api-Key
        request_body {
          max_size 32MB
        }
        reverse_proxy 127.0.0.1:8317 {
          flush_interval -1
        }
      }
    }
    @page path /proxy /proxy/*
    handle @page {
      request_body {
        max_size 16KB
      }
      reverse_proxy 127.0.0.1:8318
    }
  '';

  systemd.services.cliproxyapi-access = {
    description = "CLIProxyAPI HTTPS access over Tailscale";
    wantedBy = ["multi-user.target"];
    requires = ["tailscaled.service"];
    wants = ["network-online.target" "cliproxyapi.service"];
    after = ["tailscaled.service" "network-online.target" "cliproxyapi.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 5;
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https=8317 off";
    };
    script = ''
      ${pkgs.tailscale}/bin/tailscale serve --bg --https=8317 http://127.0.0.1:8317
    '';
  };
}
