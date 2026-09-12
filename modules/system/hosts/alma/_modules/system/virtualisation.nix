{pkgs, ...}: let
  virtualizationSocketDrivers = [
    "interface"
    "network"
    "nodedev"
    "nwfilter"
    "qemu"
    "secret"
    "storage"
  ];
  virtualizationSockets =
    builtins.concatMap (
      driver:
        map (suffix: "virt${driver}d${suffix}.socket") [
          ""
          "-ro"
          "-admin"
        ]
    )
    virtualizationSocketDrivers;
in {
  alma.packages = [
    "libvirt"
    "libvirt-client"
    "qemu-kvm"
    "virt-install"
    "virt-manager"
    "virt-viewer"
  ];
  alma.services = virtualizationSockets;
  alma.activation.virtualisation = ''
    # Keep VM images on Alma's large /home filesystem without granting QEMU
    # traversal access to the user's private home directory.
    vm_pool=/home/libvirt/images
    /usr/bin/install -d -m 0711 /home/libvirt "$vm_pool"
    if /usr/bin/virsh --connect qemu:///system pool-info default >/dev/null 2>&1; then
      current_pool=$(
        /usr/bin/virsh --connect qemu:///system pool-dumpxml default \
          | /usr/bin/sed -n 's:.*<path>\(.*\)</path>.*:\1:p'
      )
      if [[ $current_pool != "$vm_pool" ]]; then
        /usr/bin/virsh --connect qemu:///system pool-start default >/dev/null 2>&1 || true
        /usr/bin/virsh --connect qemu:///system pool-refresh default >/dev/null
        if /usr/bin/virsh --connect qemu:///system vol-list default \
          | /usr/bin/sed -n '3,$p' \
          | ${pkgs.gnugrep}/bin/grep -q '[^[:space:]]'; then
          echo "Refusing to move the non-empty default libvirt pool from $current_pool." >&2
          exit 1
        fi
        /usr/bin/virsh --connect qemu:///system pool-destroy default >/dev/null
        /usr/bin/virsh --connect qemu:///system pool-undefine default >/dev/null
      fi
    fi
    if ! /usr/bin/virsh --connect qemu:///system pool-info default >/dev/null 2>&1; then
      /usr/bin/virsh --connect qemu:///system \
        pool-define-as default dir --target "$vm_pool" >/dev/null
    fi
    if ! /usr/bin/virsh --connect qemu:///system pool-info default \
      | ${pkgs.gnugrep}/bin/grep -Eq '^State:[[:space:]]+running$'; then
      /usr/bin/virsh --connect qemu:///system pool-start default >/dev/null
    fi
    /usr/bin/virsh --connect qemu:///system pool-autostart default >/dev/null
  '';
}
