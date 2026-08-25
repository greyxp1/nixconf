{username}: {
  dnfPackages = [
    "NetworkManager"
    "alsa-ucm"
    "alsa-utils"
    "amd-gpu-firmware"
    "amd-ucode-firmware"
    "dconf"
    "dracut-config-generic"
    "git"
    "grubby"
    "intel-audio-firmware"
    "intel-gpu-firmware"
    "irqbalance"
    "kernel"
    "kernel-modules-extra"
    "linux-firmware"
    "mailcap"
    "mesa-dri-drivers"
    "microcode_ctl"
    "nvidia-gpu-firmware"
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

  dnfGroups = [
    "server-product-environment|Server"
    "development|Development Tools"
  ];

  disabledServices = [
    "firewalld.service"
    "packagekit-offline-update.service"
    "packagekit.service"
  ];

  nativeServices = [
    "NetworkManager.service"
    "getty@tty1.service"
    "getty@tty2.service"
    "irqbalance.service"
    "sshd.service"
  ];

  kernelArguments = [
    "selinux=0"
  ];

  storeScriptUnits = [
    "alma-host.service"
    "home-manager-${username}.service"
    "system-manager-path.service"
  ];
}
