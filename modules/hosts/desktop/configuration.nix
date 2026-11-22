{
  config,
  importTree,
  ...
}: let
  secrets = config.security.nix-secrets.secrets;
  tailscaleState = "/var/lib/tailscale/tailscaled.state";
in {
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

  services.scx-loader = {
    enable = true;
    config.default_sched = "scx_cosmos";
  };

  security.nix-secrets.secrets."desktop/tailscale-state" = {};

  # The first login works without secrets. Seed client state when it becomes available.
  systemd.tmpfiles.rules = [
    "C- ${tailscaleState} 0600 root root - ${secrets."desktop/tailscale-state".path}"
  ];
  systemd.services.tailscaled.unitConfig.ConditionPathExists = tailscaleState;

  imports = [
    (importTree ../../core)
    (importTree ../../graphical)
    ./_modules/sshfs.nix
    ./_modules/sunshine.nix
    ./_modules/noctalia.nix
    ./_modules/recording.nix
    ./_modules/at2005usb.nix
    ./_modules/whisrs.nix
    ./_modules/gaming.nix
    ./_modules/rocket-league.nix
    ./_modules/kovaaks.nix
    ./_modules/sober.nix
    ./_modules/nvidia.nix
    ./_modules/virt.nix
  ];
}
