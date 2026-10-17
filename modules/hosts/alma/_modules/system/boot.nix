{
  config,
  lib,
  pkgs,
  ...
}: let
  kernelArgumentManifest = pkgs.writeText "alma-kernel-arguments" (
    lib.concatStringsSep "\n" config.alma.kernelArguments + "\n"
  );
  removedKernelArgumentManifest = pkgs.writeText "alma-removed-kernel-arguments" (
    lib.concatStringsSep "\n" config.alma.removedKernelArguments + "\n"
  );
  bootHealth = pkgs.writeText "nixconf-boot-health" ''
    #!/bin/bash
    set -euo pipefail

    valid_boot_artifacts() {
      local version=$1
      local kernel=/boot/vmlinuz-$version
      local initramfs=/boot/initramfs-$version.img
      [[ -s $kernel && -s $initramfs ]] \
        && (( $(/usr/bin/stat -c %s "$initramfs") >= 32 * 1024 * 1024 ))
    }

    case ''${1:-check} in
      check)
        running_version=$(/usr/bin/uname -r)
        running_kernel=/boot/vmlinuz-$running_version
        if ! valid_boot_artifacts "$running_version"; then
          echo "The running kernel $running_version has incomplete boot artifacts." >&2
          exit 1
        fi

        default_kernel=$(/usr/sbin/grubby --default-kernel 2>/dev/null || true)
        default_version=''${default_kernel#/boot/vmlinuz-}
        if [[ $default_kernel != /boot/vmlinuz-* ]] \
          || ! valid_boot_artifacts "$default_version"; then
          echo "GRUB's default kernel has incomplete boot artifacts; restoring $running_version." >&2
          /usr/sbin/grubby --set-default="$running_kernel"
          echo "The unsafe GRUB default was repaired. Re-run the rebuild after reviewing /boot." >&2
          exit 1
        fi
        ;;
      promote)
        target_version=''${2:?kernel version is required}
        target_kernel=/boot/vmlinuz-$target_version
        target_initramfs=/boot/initramfs-$target_version.img
        if ! valid_boot_artifacts "$target_version" \
          || ! /usr/bin/lsinitrd "$target_initramfs" >/dev/null 2>&1 \
          || ! /usr/sbin/grubby --info="$target_kernel" >/dev/null 2>&1; then
          echo "Refusing to promote kernel $target_version: its boot artifacts are incomplete." >&2
          exit 1
        fi
        /usr/sbin/grubby --set-default="$target_kernel"
        ;;
      *)
        echo "Usage: nixconf-boot-health [check | promote KERNEL_VERSION]" >&2
        exit 2
        ;;
    esac
  '';
in {
  environment.etc = {
    "dracut.conf.d/99-nixconf-no-rescue.conf" = {
      mode = "0644";
      replaceExisting = true;
      text = ''
        dracut_rescue_image="no"
      '';
    };
    "kernel/install.d/99-nixconf-promote.install" = {
      mode = "0755";
      replaceExisting = true;
      text = ''
        #!/bin/bash
        [[ $1 == add ]] || exit 0
        if [[ ! -x /usr/local/sbin/nixconf-boot-health ]]; then
          echo "Refusing to install a kernel without the native nixconf boot-health check." >&2
          exit 1
        fi
        exec /usr/local/sbin/nixconf-boot-health promote "$2"
      '';
    };
    "sysconfig/kernel" = {
      mode = "0644";
      replaceExisting = true;
      text = ''
        UPDATEDEFAULT=no
        DEFAULTKERNEL=kernel-core
      '';
    };
    "selinux/config" = {
      mode = "0644";
      replaceExisting = true;
      text = ''
        SELINUX=disabled
        SELINUXTYPE=targeted
      '';
    };
  };
  alma.activation.bootPrepare = ''
    /usr/bin/install -d -m 0755 /usr/local/sbin
    /usr/bin/install -m 0755 ${bootHealth} /usr/local/sbin/nixconf-boot-health
    if [[ -x /usr/sbin/restorecon ]]; then
      /usr/sbin/restorecon -F /usr/local/sbin/nixconf-boot-health
    fi
    /usr/local/sbin/nixconf-boot-health check
  '';
  alma.activation.bootImages = ''
    if [[ -e $pending_initramfs ]]; then
      kernel_versions=$(/usr/bin/rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n')
      while IFS= read -r kernel_version; do
        initramfs="/boot/initramfs-$kernel_version.img"
        # Preserve each bootable image until its replacement is complete.
        /usr/bin/dracut -f "$initramfs.new" "$kernel_version"
        /usr/bin/lsinitrd "$initramfs.new" >/dev/null
        /usr/bin/mv -f "$initramfs.new" "$initramfs"
        if [[ -x /usr/sbin/restorecon ]]; then
          /usr/sbin/restorecon -F "$initramfs"
        fi
      done <<< "$kernel_versions"
      /usr/bin/rm -f "$pending_initramfs"
    fi

    # Kdump is not useful on this portable workstation and consumes scarce
    # /boot space once per installed kernel.
    while IFS= read -r -d $'\0' kdump_image; do
      /usr/bin/rm -f -- "$kdump_image"
    done < <(
      /usr/bin/find /boot -xdev -maxdepth 1 -type f \
        -name 'initramfs-*kdump.img' -print0
    )
    machine_id=$(/usr/bin/tr -d '\n' < /etc/machine-id)
    rescue_paths=(
      "/boot/.vmlinuz-0-rescue-$machine_id.hmac"
      "/boot/initramfs-0-rescue-$machine_id.img"
      "/boot/vmlinuz-0-rescue-$machine_id"
      "/boot/loader/entries/$machine_id-0-rescue.conf"
    )
    for rescue_path in "''${rescue_paths[@]}"; do
      if [[ -e $rescue_path || -L $rescue_path ]]; then
        /usr/bin/unlink -- "$rescue_path"
      fi
    done
  '';
  alma.activation.kernelArguments = ''
    previous_kernel_arguments="$state_dir/kernel-arguments"
    if [[ -f $previous_kernel_arguments ]]; then
      while IFS= read -r argument; do
        [[ -z $argument ]] && continue
        if ! ${pkgs.gnugrep}/bin/grep -Fxq "$argument" ${kernelArgumentManifest}; then
          /usr/sbin/grubby --update-kernel=ALL --remove-args="$argument"
        fi
      done < "$previous_kernel_arguments"
    fi
    while IFS= read -r argument; do
      [[ -z $argument ]] || /usr/sbin/grubby --update-kernel=ALL --args="$argument"
    done < ${kernelArgumentManifest}
    while IFS= read -r argument; do
      [[ -z $argument ]] || /usr/sbin/grubby --update-kernel=ALL --remove-args="$argument"
    done < ${removedKernelArgumentManifest}
    /usr/bin/install -m 0644 ${kernelArgumentManifest} "$previous_kernel_arguments.new"
    /usr/bin/mv -f "$previous_kernel_arguments.new" "$previous_kernel_arguments"

    /usr/local/sbin/nixconf-boot-health check
  '';
}
