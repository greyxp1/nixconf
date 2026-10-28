{
  lib,
  pkgs,
  ...
}: {
  services.cliproxyapi = {
    enable = true;
    # Puts the reset time in the cooldown message so T3 Code can resume threads after it.
    package = pkgs.cliproxyapi.overrideAttrs (old: {
      patches = old.patches or [] ++ [./cliproxyapi-cooldown-reset.patch];
    });
    settings = {
      config-version = 8;
      server = {
        host = "127.0.0.1";
        trusted-proxies = ["127.0.0.1" "::1"];
      };
      management = {
        allow-remote = true;
        secret-key._secret = "/persistent/secrets/cliproxyapi/management-key";
      };
      access.api-keys = [
        {_secret = "/persistent/secrets/cliproxyapi/grey-key";}
        {_secret = "/persistent/secrets/cliproxyapi/friend-key";}
      ];
      routing = {
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
