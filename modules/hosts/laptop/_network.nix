{pkgs, ...}: {
  services.tailscale = {
    useRoutingFeatures = "client";
    extraDaemonFlags = [
      "--config=${pkgs.writeText "tailscale.json" (builtins.toJSON {
        version = "alpha0";
        locked = false;
        # The trailing slash avoids normalization to the blocked controlplane endpoint.
        serverURL = "https://login.tailscale.com/";
      })}"
    ];
  };
  systemd.user.services.t3code.environment = {
    T3CODE_TAILSCALE_SERVE = "true";
    TUNNEL_TRANSPORT_PROTOCOL = "http2";
  };
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeShellScript "school-exit-node-dispatcher" ''
        [[ ''${1:-} = tailscale0 ]] && exit 0
        case ''${2:-} in
          up|down|dhcp4-change)
            ${pkgs.systemd}/bin/systemctl start --no-block school-exit-node.service
            ;;
        esac
      '';
    }
  ];

  systemd.timers.school-exit-node = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      AccuracySec = "1s";
    };
  };
  systemd.services.school-exit-node = {
    description = "Use server as an exit node on the school network";
    wantedBy = ["multi-user.target"];
    after = ["NetworkManager.service" "tailscaled.service"];
    requires = ["tailscaled.service"];
    path = [pkgs.networkmanager pkgs.tailscale pkgs.jq];
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 10;
    };
    script = ''
      exit_node=""
      if nmcli -g IP4.DOMAIN,IP4.SEARCHES device show | jq -Rse '
        [splits("[[:space:],:]+")]
        | any(. == "cmontmorency.qc.ca" or endswith(".cmontmorency.qc.ca"))
      ' >/dev/null; then
        exit_node=$(tailscale status --json | jq -r '
          [.Peer[]? | select(.HostName == "server" and .Online and .ExitNodeOption)
            | .TailscaleIPs[0]][0] // ""
        ')
      fi
      tailscale set --exit-node="$exit_node" --exit-node-allow-lan-access
    '';
  };
}
