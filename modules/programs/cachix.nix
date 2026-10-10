{
  flake.nixosModules.cachix.nix.settings = import ../system/_cache.nix;

  flake.cachixPublisherModule = {pkgs, ...}: {
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
      after = ["network-online.target"];
      serviceConfig = {
        User = "grey";
        Slice = "nixbuild.slice";
        Nice = 19;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        OOMScoreAdjust = 500;
        RuntimeDirectory = "cachix-publisher";
        RuntimeDirectoryMode = "0700";
        ExecStart = "${pkgs.cachix}/bin/cachix --config /home/grey/.config/cachix/cachix.dhall daemon run --socket /run/cachix-publisher/socket --no-remote-stop --jobs 2 grey-nixconf";
        KillSignal = "SIGINT";
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };
  };
}
