{
  config,
  importTree,
  lib,
  ...
}: {
  imports = [
    (importTree ../../core)
    (importTree ../../graphical)
    ./_hardware.nix
    ./_network.nix
  ];

  swapDevices = [
    {
      device = "/persistent/swapfile";
      size = 8192;
    }
  ];

  # Temporary server cache, delete with harmonia.nix once laptop and alma are dropped.
  nix.settings = {
    extra-substituters = ["https://greyxp1.root.sx/nix-cache"];
    extra-trusted-public-keys = ["greyxp1.root.sx-1:6g4cMFPtBQhoHsPcDFw/aNl8xhR5yYoZyjYqrmOjxAA="];
  };

  services.upower.enable = true;
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    grub.enable = true;
  };

  disko.devices.disk.main = {
    content.partitions = {
      bios = {
        size = "1M";
        type = "EF02";
        priority = 1;
      };
      ESP = {
        name = "boot";
        size = "1G";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/boot";
        };
      };
    };
  };

  programs = {
    # Build on the server, then substitute everything from its cache instead of building locally.
    fish.shellAliases.rebuild = lib.mkForce "tailscale ssh grey@server true && nix build --store ssh-ng://grey@server --no-link ${config.programs.nh.flake}#nixosConfigurations.laptop.config.system.build.toplevel && nh os switch --max-jobs 0";

    # Ironlake only supports GLES 2, so Chromium's GLES 3 initialization fails.
    helium.flags = ["--disable-gpu"];
  };
  programs.gpu-screen-recorder.replay.enable = lib.mkForce false;
  systemd.user.services.swaylock.wantedBy = ["graphical-session.target"];
}
