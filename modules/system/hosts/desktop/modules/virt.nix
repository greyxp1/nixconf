{
  flake.nixosModules.virt = {config, lib, pkgs, ...}: {
    options.custom.virt.enable = lib.mkEnableOption "virtualization tools";
    config = lib.mkIf config.custom.virt.enable {
      environment.systemPackages = with pkgs; [
        spice-gtk
        (writeScriptBin "create-nixos-vm" ''
          #!${pkgs.dash}/bin/dash
          set -eu
          [ -n "$1" ] && [ -n "$2" ] || { echo "Usage: create-nixos-vm <name> <iso>"; exit 1; }

          VIRSH="${pkgs.libvirt}/bin/virsh --connect qemu:///system"
          OVMF_CODE=/run/libvirt/nix-ovmf/edk2-x86_64-code.fd
          OVMF_VARS=/run/libvirt/nix-ovmf/edk2-i386-vars.fd

          if $VIRSH dominfo "$1" >/dev/null 2>&1; then
            printf "VM '%s' already exists. Destroy and recreate? [y/N] " "$1"
            read -r answer
            case "$answer" in [yY]*) ;; *) exit 0 ;; esac
            $VIRSH destroy "$1" 2>/dev/null || true
            $VIRSH undefine "$1" --nvram --remove-all-storage 2>/dev/null || $VIRSH undefine "$1" --nvram
          fi

          $VIRSH net-autostart default >/dev/null 2>&1 || true
          $VIRSH net-start default >/dev/null 2>&1 || true
          $VIRSH pool-autostart default >/dev/null 2>&1 || true
          $VIRSH pool-start default >/dev/null 2>&1 || true

          echo "==> Creating '$1'..."
          virt-install \
            --connect qemu:///system \
            --name "$1" \
            --memory 8192 \
            --vcpus 4 \
            --memorybacking source.type=memfd,access.mode=shared \
            --disk size=40,pool=default,bus=virtio \
            --os-variant=nixos-unstable \
            --boot loader="$OVMF_CODE",loader.readonly=yes,loader.type=pflash,nvram.template="$OVMF_VARS" \
            --network network=default,model=virtio \
            --noautoconsole \
            --cdrom "$2" \
            --video virtio,accel3d=on \
            --graphics spice,listen=none,image.compression=off \
            --graphics egl-headless,gl.rendernode=/dev/dri/renderD128

          systemd-run --user --quiet --collect virt-manager --connect qemu:///system --show-domain-console "$1"
          kill $PPID
        '')
      ];

      users.users.grey.extraGroups = ["libvirtd" "video" "render"];

      networking.firewall.trustedInterfaces = ["virbr0"];

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
        firewallBackend = "nftables";
        onShutdown = "shutdown";
        onBoot = "ignore";
        qemu = {
          runAsRoot = true;
          package = pkgs.qemu_kvm.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
            postInstall = (old.postInstall or "")
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

      systemd.sockets = {
        libvirtd.wantedBy = lib.mkForce [];
        libvirtd-ro.wantedBy = lib.mkForce [];
        libvirtd-admin.wantedBy = lib.mkForce [];
      }
      // lib.genAttrs (
        lib.concatMap (driver: [
          "virt${driver}d"
          "virt${driver}d-ro"
          "virt${driver}d-admin"
        ]) [
          "qemu"
          "interface"
          "network"
          "nodedev"
          "nwfilter"
          "storage"
          "proxy"
        ]
      ) (_: {wantedBy = ["sockets.target"];});

      systemd.services = {
        libvirtd-config.serviceConfig.RemainAfterExit = true;
        libvirtd.wantedBy = lib.mkForce [];
        virtqemud = {
          requires = ["libvirtd-config.service"];
          after = ["libvirtd-config.service"];
          path = [
            config.virtualisation.libvirtd.qemu.package
            pkgs.netcat
          ];
        };
        virtnetworkd = {
          requires = ["libvirtd-config.service"];
          after = ["libvirtd-config.service"];
          path = with pkgs; [
            dnsmasq
            iproute2
            iptables
            nftables
          ];
        };
        virtstoraged = {
          requires = ["libvirtd-config.service"];
          after = ["libvirtd-config.service"];
          path = [config.virtualisation.libvirtd.qemu.package];
        };
      };
    };
  };
}
