{
  lib,
  pkgs,
  uid,
  username,
  ...
}: let
  cache = import ../_cache.nix;
in {
  imports = [
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
      "9" = [];
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
    ];

    userGroups = [
      "docker"
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

  environment.pathsToLink = [
    "/share/applications"
    "/share/zsh"
    "/share/xdg-desktop-portal"
  ];
  environment.systemPackages = [pkgs.zsh];

  systemd.maskedUnits = [
    "NetworkManager-wait-online.service"
    "firewalld.service"
    "kdump.service"
    "packagekit-offline-update.service"
    "packagekit.service"
  ];

  # Reconcile explicitly after switching; boot only needs the immutable profile.
  systemd = {
    targets.system-manager.wants = ["system-manager-path.service"];
    services."home-manager-${username}" = {
      wantedBy = lib.mkForce [];
      restartIfChanged = false;
      environment = {
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${toString uid}/bus";
        PATH = lib.mkForce "/etc/profiles/per-user/${username}/bin:/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin";
        XDG_RUNTIME_DIR = "/run/user/${toString uid}";
      };
    };
  };
  environment.etc."systemd/system/nix-daemon.service.d/nixconf.conf" = {
    mode = "0644";
    replaceExisting = true;
    text = "[Service]\nCPUSchedulingPolicy=idle\nIOSchedulingClass=idle\n";
  };
}
