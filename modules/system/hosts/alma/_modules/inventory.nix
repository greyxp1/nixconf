{username}: let
  virtualizationPackages = [
    "libvirt"
    "libvirt-client"
    "qemu-kvm"
    "virt-install"
    "virt-manager"
    "virt-viewer"
  ];
  virtualizationSocketDrivers = [
    "interface"
    "network"
    "nodedev"
    "nwfilter"
    "qemu"
    "secret"
    "storage"
  ];
  virtualizationSockets = builtins.concatMap (
    driver:
      map (suffix: "virt${driver}d${suffix}.socket") [
        ""
        "-ro"
        "-admin"
      ]
  ) virtualizationSocketDrivers;
  commonDnfPackages = [
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
  ] ++ virtualizationPackages;
in {
  dnfPackagesByMajor = {
    # Alma 9 ships all hardware firmware in linux-firmware. Alma 10 splits
    # common GPU and CPU firmware into packages that must be requested too.
    "9" = commonDnfPackages;
    "10" =
      commonDnfPackages
      ++ [
        "amd-gpu-firmware"
        "amd-ucode-firmware"
        "intel-audio-firmware"
        "intel-gpu-firmware"
        "nvidia-gpu-firmware"
      ];
  };

  dnfGroups = [
    "server-product-environment|Server"
    "development|Development Tools"
  ];

  disabledServices = [
    "firewalld.service"
    "kdump.service"
    "packagekit-offline-update.service"
    "packagekit.service"
  ];

  nativeServices = [
    "NetworkManager.service"
    "getty@tty1.service"
    "getty@tty2.service"
    "irqbalance.service"
    "sshd.service"
  ] ++ virtualizationSockets;

  nativeUserGroups = [
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

  storeScriptUnits = [
    "alma-host.service"
    "home-manager-${username}.service"
    "system-manager-path.service"
  ];
}
