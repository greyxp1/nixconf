{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    spice-gtk
    (writeScriptBin "create-nixos-vm" ''
      #!${pkgs.dash}/bin/dash
      if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: create-nixos-vm <vm-name> <path-to-nixos-iso>"
        exit 1
      fi
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
      virt-manager --connect qemu:///system --show-domain-console "$1" &
    '')
  ];

  users.users.grey.extraGroups = [ "libvirtd" "video" "render" ];

  programs = {
    virt-manager.enable = true;
    dconf.profiles.user.databases = [{
      settings."org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
    }];
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = true;
      package = pkgs.qemu_kvm.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
        postInstall = (old.postInstall or "") + ''
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
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "libvirt-net-start" ''
        #!${pkgs.dash}/bin/dash
        ${pkgs.libvirt}/bin/virsh net-autostart default || true
        ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
      '';
    };
  };
}
