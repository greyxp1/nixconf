{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    spice-gtk
    (writeScriptBin "create-nixos-vm" ''
      #!${pkgs.dash}/bin/dash
      set -eu
      [ -n "$1" ] && [ -n "$2" ] || { echo "Usage: create-nixos-vm <name> <iso>"; exit 1; }

      VIRSH="${pkgs.libvirt}/bin/virsh --connect qemu:///system"

      if $VIRSH dominfo "$1" >/dev/null 2>&1; then
        printf "VM '%s' already exists. Destroy and recreate? [y/N] " "$1"
        read -r answer
        case "$answer" in [yY]*) ;; *) exit 0 ;; esac
        $VIRSH destroy "$1" 2>/dev/null || true
        $VIRSH undefine "$1" --nvram --remove-all-storage 2>/dev/null || $VIRSH undefine "$1" --nvram
      fi

      echo "==> Creating '$1'..."
      virt-install \
        --connect qemu:///system \
        --name "$1" \
        --memory 8192 \
        --vcpus 4 \
        --memorybacking source.type=memfd,access.mode=shared \
        --disk size=40,pool=default,bus=virtio \
        --os-variant=nixos-unstable \
        --boot uefi \
        --network network=default,model=virtio \
        --noautoconsole \
        --cdrom "$2" \
        --video virtio,accel3d=on \
        --graphics spice,listen=none,image.compression=off \
        --graphics egl-headless,gl.rendernode=/dev/dri/renderD128

      nohup virt-manager --connect qemu:///system --show-domain-console "$1" >/dev/null 2>&1 &
      kill $PPID
    '')
  ];

  users.users.grey.extraGroups = ["libvirtd" "video" "render"];

  programs = {
    virt-manager.enable = true;
    dconf.profiles.user.databases = [
      {
        settings."org/virt-manager/virt-manager/connections" = {
          autoconnect = ["qemu:///system"];
          uris = ["qemu:///system"];
        };
      }
    ];
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = true;
      package = pkgs.qemu_kvm.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
        postInstall =
          (old.postInstall or "")
          + ''
            wrapProgram $out/bin/qemu-system-x86_64 \
              --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
          '';
      });
      verbatimConfig = ''
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/nvidiactl", "/dev/nvidia0",
          "/dev/nvidia-modeset", "/dev/dri/renderD128"
        ]
      '';
    };
  };

  systemd.services.libvirt-default-network = {
    description = "Autostart libvirt default network";
    after = ["libvirtd.service"];
    requires = ["libvirtd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "libvirt-net-start" ''
        ${pkgs.libvirt}/bin/virsh net-autostart default || true
        ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
      '';
    };
  };
}
