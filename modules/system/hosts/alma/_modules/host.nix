{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cache = import ../_cache.nix;
  schoolExitNode = pkgs.writeShellScript "alma-school-exit-node" ''
    set -euo pipefail
    exit_node=""
    if /usr/bin/nmcli -g UUID connection show --active | ${pkgs.gnugrep}/bin/grep -Fxq 77f514d1-e780-4c88-999b-208d242db751; then
      exit_node=$(${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -r '
        [.Peer[]? | select(.HostName == "desktop" and .Online and .ExitNodeOption)
          | .TailscaleIPs[0]][0] // ""
      ')
    fi
    ${pkgs.tailscale}/bin/tailscale set --exit-node="$exit_node" --exit-node-allow-lan-access
  '';
in {
  imports = [
    inputs.self.t3codeSystemModule
    ../../../../programs/remote/_alma.nix
    ./system
    ./system/packages.nix
    ./system/boot.nix
    ./system/login.nix
    ./system/services.nix
    ./system/virtualisation.nix
    ./system/desktop.nix
  ];

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.allowUnfree = true;
  };

  alma = {
    hostName = "alma";
    timeZone = "America/Montreal";
    defaultTarget = "multi-user.target";
    packages = [
      "NetworkManager"
      "alsa-ucm"
      "alsa-utils"
      "dconf"
      "dracut-config-generic"
      "git"
      "grubby"
      "irqbalance"
      "libatomic"
      "kernel"
      "kernel-modules-extra"
      "linux-firmware"
      "mailcap"
      "mesa-dri-drivers"
      "microcode_ctl"
      "openssh-clients"
      "openssh-server"
      "pipewire"
      "pipewire-alsa"
      "pipewire-pulseaudio"
      "polkit"
      "rtkit"
      "sudo"
      "udisks2"
      "wireplumber"
      "xdg-desktop-portal"
      "xdg-desktop-portal-gtk"
      "zram-generator"
    ];
    # Alma 10 splits firmware that Alma 9 bundles in linux-firmware.
    extraPackagesByMajor = {
      # VMware's bundled OVF Tool needs the legacy libnsl.so.1 library.
      "9" = ["libnsl"];
      "10" = [
        "amd-gpu-firmware"
        "amd-ucode-firmware"
        "intel-audio-firmware"
        "intel-gpu-firmware"
        "nvidia-gpu-firmware"
      ];
    };
    packageGroups = {
      server-product-environment = "Server";
      development = "Development Tools";
    };
    services = [
      "NetworkManager.service"
      "getty@tty1.service"
      "getty@tty2.service"
      "irqbalance.service"
      "sshd.service"
      "tailscaled.service"
      "t3code.service"
      "alma-school-exit-node.service"
    ];

    userGroups = [
      "docker"
      "input"
      "libvirt"
      "render"
      "video"
      "wheel"
    ];

    kernelArguments = [
      "selinux=0"
    ];

    removedKernelArguments = [
      "crashkernel"
    ];
  };

  nix = {
    enable = true;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      trusted-users = ["@wheel"];
      max-jobs = 2;
      cores = 6;
      warn-dirty = false;
      extra-substituters = cache.substituters;
      extra-trusted-public-keys = cache.trusted-public-keys;
    };
  };
  environment.etc."nix/nix.conf".mode = "0644";
  environment.etc."NetworkManager/dispatcher.d/90-school-exit-node" = {
    mode = "0755";
    source = pkgs.writeShellScript "school-exit-node-dispatcher" ''
      [[ ''${1:-} = tailscale0 ]] && exit 0
      case ''${2:-} in
        up|down|dhcp4-change)
          /usr/bin/systemctl start alma-school-exit-node.service
          ;;
      esac
    '';
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/zsh"
    "/share/xdg-desktop-portal"
  ];
  environment.systemPackages = [pkgs.tailscale];
  alma.activation.t3code = ''
    /usr/bin/loginctl enable-linger grey
  '';
  systemd.services.t3code.environment.TUNNEL_TRANSPORT_PROTOCOL = "http2";

  systemd.maskedUnits = [
    "NetworkManager-wait-online.service"
    "firewalld.service"
    "kdump.service"
    "packagekit-offline-update.service"
    "packagekit.service"
  ];

  # Reconcile explicitly after switching; boot only needs the immutable profile.
  systemd = {
    timers.alma-school-exit-node = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "30s";
        AccuracySec = "1s";
      };
    };
    services.alma-school-exit-node = {
      description = "Use desktop as an exit node on the school network";
      wantedBy = ["multi-user.target"];
      unitConfig.StartLimitIntervalSec = 0;
      after = ["NetworkManager.service" "tailscaled.service"];
      requires = ["tailscaled.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = schoolExitNode;
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
    services.tailscaled = {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641";
        StateDirectory = "tailscale";
        RuntimeDirectory = "tailscale";
        Restart = "on-failure";
      };
    };
    targets.system-manager.wants = ["system-manager-path.service"];
  };
  environment.etc."systemd/system/nix-daemon.service.d/nixconf.conf" = {
    mode = "0644";
    replaceExisting = true;
    text = "[Service]\nCPUSchedulingPolicy=idle\nIOSchedulingClass=idle\n";
  };
}
