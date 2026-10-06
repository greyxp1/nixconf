{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.desktop = mkHost "desktop" {
    disko.devices.disk.main.device = import ./_device.nix;
    services.scx = {
      enable = true;
      scheduler = "scx_cosmos";
    };
    hardware.cpu.amd.updateMicrocode = true;
    powerManagement.cpuFreqGovernor = "performance";
    boot = {
      kernelModules = ["kvm-amd" "ntsync"];
      kernelParams = [
        "amd_pstate=active" # AMD CPU freq scaling driver
        "8250.nr_uarts=0" # suppress legacy COM port probes
      ];

      initrd = {
        systemd.network.wait-online.enable = false;
        availableKernelModules = ["nvme"];
      };
    };

    imports = [
      ({pkgs, ...}: {
        environment.systemPackages = [pkgs.cachix];
        nix.settings.post-build-hook = pkgs.writeShellScript "publish-to-cachix" ''
          set -f
          IFS=' '
          ${pkgs.coreutils}/bin/timeout 5 ${pkgs.cachix}/bin/cachix daemon push \
            --socket /run/cachix-publisher/socket $OUT_PATHS ||
            echo "Cachix publisher unavailable. Built outputs were not queued." >&2
        '';
        systemd.services.cachix-publisher = {
          description = "Publish Nix build outputs to grey-nixconf";
          wantedBy = ["multi-user.target"];
          wants = ["network-online.target"];
          after = ["network-online.target" "nix-daemon.service"];
          serviceConfig = {
            User = "grey";
            RuntimeDirectory = "cachix-publisher";
            RuntimeDirectoryMode = "0700";
            ExecStart = "${pkgs.cachix}/bin/cachix --config /home/grey/.config/cachix/cachix.dhall daemon run --socket /run/cachix-publisher/socket --no-remote-stop --jobs 2 grey-nixconf";
            KillSignal = "SIGINT";
            Restart = "on-failure";
            RestartSec = "30s";
          };
        };
      })
      ./_modules/noctalia.nix
      ./_modules/at2005usb.nix
      ./_modules/gaming.nix
      ./_modules/kovaaks.nix
      ./_modules/sober.nix
      ./_modules/nvidia.nix
      ./_modules/virt.nix
    ];
  };
}
