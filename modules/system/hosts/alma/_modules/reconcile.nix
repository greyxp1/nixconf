{username}: {
  config,
  lib,
  pkgs,
  ...
}: let
  inventory = import ./inventory.nix {inherit username;};
  inherit
    (inventory)
    disabledServices
    dnfGroups
    dnfPackagesByMajor
    kernelArguments
    nativeServices
    nativeUserGroups
    removedKernelArguments
    ;

  dnfManifests = lib.mapAttrs (major: packages:
    pkgs.writeText "alma-${major}-dnf-packages" (
      lib.concatStringsSep "\n" packages + "\n"
    ))
  dnfPackagesByMajor;
  selectDnfManifest = lib.concatStringsSep "\n  " (
    lib.mapAttrsToList (major: manifest: "${major}) dnf_manifest=${manifest} ;;")
    dnfManifests
  );
  dnfGroupManifest = pkgs.writeText "alma-dnf-groups" (
    lib.concatStringsSep "\n" dnfGroups + "\n"
  );
  disabledServiceManifest = pkgs.writeText "alma-disabled-services" (
    lib.concatStringsSep "\n" disabledServices + "\n"
  );
  serviceManifest = pkgs.writeText "alma-native-services" (
    lib.concatStringsSep "\n" nativeServices + "\n"
  );
  kernelArgumentManifest = pkgs.writeText "alma-kernel-arguments" (
    lib.concatStringsSep "\n" kernelArguments + "\n"
  );
  removedKernelArgumentManifest = pkgs.writeText "alma-removed-kernel-arguments" (
    lib.concatStringsSep "\n" removedKernelArguments + "\n"
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
  heliumPolicy =
    pkgs.writeText "helium-policy.json"
    config.home-manager.users.${username}.programs.helium.finalPolicyJson;
  gpuSetup = config.home-manager.users.${username}.targets.genericLinux.gpu.setupPackage;
  loginShellLauncher = pkgs.writeText "nixconf-zsh" ''
    #!/bin/sh
    if [ -x /run/system-manager/sw/bin/zsh ]; then
      exec /run/system-manager/sw/bin/zsh --login "$@"
    fi
    echo "The declarative Zsh is unavailable; starting Alma Bash." >&2
    exec /bin/bash -l "$@"
  '';
  legacyShellLauncher = pkgs.writeText "nixconf-nu" ''
    #!/bin/sh
    export SHELL=/usr/local/bin/nixconf-zsh
    exec /usr/local/bin/nixconf-zsh "$@"
  '';
in {
  systemd.services.alma-host = {
    description = "Reconcile the AlmaLinux host";
    after = ["system-manager-path.service"];
    requires = ["system-manager-path.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "15min";
    };
    script = ''
      set -euo pipefail
      export LC_ALL=C
      export PATH=/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

      source /etc/os-release
      alma_major=''${VERSION_ID%%.*}
      case "$alma_major" in
        ${selectDnfManifest}
        *)
          echo "Unsupported AlmaLinux major version: ''${VERSION_ID:-unknown}" >&2
          exit 1
          ;;
      esac

      state_dir=/var/lib/nixconf
      previous_packages="$state_dir/dnf-packages"
      previous_groups="$state_dir/dnf-groups"
      previous_services="$state_dir/native-services"
      previous_kernel_arguments="$state_dir/kernel-arguments"
      /usr/bin/install -d -m 0755 "$state_dir"

      install_helium_policy() {
        local target=$1
        /usr/bin/install -d -m 0755 "$(/usr/bin/dirname "$target")"
        if [[ ! -f $target ]] || ! /usr/bin/cmp -s ${heliumPolicy} "$target"; then
          if /usr/bin/pgrep -x helium >/dev/null; then
            echo "Refusing to change Helium policy while Helium is running: $target" >&2
            exit 1
          fi
          /usr/bin/install -m 0644 ${heliumPolicy} "$target"
          if [[ -x /usr/sbin/restorecon ]]; then
            /usr/sbin/restorecon -F "$target"
          fi
        fi
      }
      install_helium_policy /etc/chromium/policies/managed/helium.json
      install_helium_policy /etc/helium/policies/managed/helium.json
      if [[ ! -e $state_dir/helium-policy-reconciled ]]; then
        /usr/bin/install -m 0644 /dev/null "$state_dir/helium-policy-reconciled"
      fi

      use_https_repositories() {
        # The school network blocks HTTP. Alma's mirror service can
        # return HTTP mirrors, so use Alma's shipped HTTPS base URLs.
        for repo_file in /etc/yum.repos.d/almalinux-*.repo; do
          [[ -f $repo_file ]] || continue
          /usr/bin/sed -i \
            -e 's|^mirrorlist=|# mirrorlist=|' \
            -e 's|^# *baseurl=https://repo.almalinux.org/almalinux/|baseurl=https://repo.almalinux.org/almalinux/|' \
            "$repo_file"
        done
      }
      use_https_repositories

      /usr/bin/install -d -m 0755 /usr/local/sbin
      /usr/bin/install -m 0755 ${bootHealth} /usr/local/sbin/nixconf-boot-health
      if [[ -x /usr/sbin/restorecon ]]; then
        /usr/sbin/restorecon -F /usr/local/sbin/nixconf-boot-health
      fi
      /usr/local/sbin/nixconf-boot-health check

      while IFS= read -r service; do
        [[ -z $service ]] || /usr/bin/systemctl stop "$service"
      done < ${disabledServiceManifest}

      declared=()
      missing=()
      rebuild_initramfs=false
      while IFS= read -r package; do
        [[ -z $package ]] && continue
        declared+=("$package")
        if ! /usr/bin/rpm --quiet -q "$package"; then
          missing+=("$package")
          case $package in
            *-firmware|dracut-config-generic|kernel-modules-extra|microcode_ctl)
              rebuild_initramfs=true
              ;;
          esac
        fi
      done < "$dnf_manifest"
      if (( ''${#missing[@]} )); then
        /usr/bin/dnf install -y "''${missing[@]}"
      fi
      # Protect native packages owned by this configuration from group
      # removal, even when DNF originally installed them as group members.
      unprotected=()
      for package in "''${declared[@]}"; do
        if /usr/bin/dnf repoquery --installed --qf '%{reason}' "$package" \
          | ${pkgs.gnugrep}/bin/grep -qxv user; then
          unprotected+=("$package")
        fi
      done
      if (( ''${#unprotected[@]} )); then
        /usr/bin/dnf mark install "''${unprotected[@]}"
      fi

      installed_groups=$(/usr/bin/dnf -q group list --installed \
        | /usr/bin/sed -E 's/^[[:space:]]+//')
      missing_groups=()
      while IFS='|' read -r group_id group_name; do
        [[ -z $group_id ]] && continue
        if ! ${pkgs.gnugrep}/bin/grep -Fxq "$group_name" <<< "$installed_groups"; then
          missing_groups+=("$group_id")
        fi
      done < ${dnfGroupManifest}
      if (( ''${#missing_groups[@]} )); then
        /usr/bin/dnf group install -y "''${missing_groups[@]}"
      fi
      removed_groups=()
      if [[ -f $previous_groups ]]; then
        while IFS='|' read -r group_id group_name; do
          [[ -z $group_id ]] && continue
          if ! ${pkgs.gnugrep}/bin/grep -Fxq "$group_id|$group_name" ${dnfGroupManifest}; then
            removed_groups+=("$group_id")
          fi
        done < "$previous_groups"
      fi
      if (( ''${#removed_groups[@]} )); then
        # Keep dependencies in place until they are reviewed explicitly;
        # group autoremove is too broad for a school workstation.
        /usr/bin/dnf --noautoremove group remove -y "''${removed_groups[@]}"
      fi
      /usr/bin/install -m 0644 ${dnfGroupManifest} "$previous_groups.new"
      /usr/bin/mv -f "$previous_groups.new" "$previous_groups"

      removed=()
      if [[ -f $previous_packages ]]; then
        while IFS= read -r package; do
          [[ -z $package ]] && continue
          if ! ${pkgs.gnugrep}/bin/grep -Fxq "$package" "$dnf_manifest" \
            && /usr/bin/rpm --quiet -q "$package"; then
            removed+=("$package")
          fi
        done < "$previous_packages"
      fi
      if (( ''${#removed[@]} )); then
        for package in "''${removed[@]}"; do
          # RPM erases exactly one package and refuses when another
          # installed package still depends on it. DNF's solver could
          # otherwise remove an unrelated, manually installed program.
          /usr/bin/rpm -e "$package"
        done
      fi
      /usr/bin/install -m 0644 "$dnf_manifest" "$previous_packages.new"
      /usr/bin/mv -f "$previous_packages.new" "$previous_packages"
      if [[ $rebuild_initramfs == true ]]; then
        /usr/bin/dracut -f --kver "$(/usr/bin/uname -r)"
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

      unix_chkpwd=/usr/sbin/unix_chkpwd
      if [[ ! -x $unix_chkpwd \
        || $(/usr/bin/stat -c %U "$unix_chkpwd") != root \
        || ! -u $unix_chkpwd ]]; then
        echo "$unix_chkpwd must exist, be owned by root, and be setuid" >&2
        exit 1
      fi
      /usr/bin/systemd-tmpfiles --create \
        /etc/tmpfiles.d/nixconf-journal.conf \
        /etc/tmpfiles.d/nixconf-pam.conf

      shell=/usr/local/bin/nixconf-zsh
      zsh=/run/system-manager/sw/bin/zsh
      if [[ ! -x $zsh ]]; then
        echo "System Manager's Zsh is missing at $zsh" >&2
        exit 1
      fi
      /usr/bin/install -d -m 0755 /usr/local/bin
      /usr/bin/install -m 0755 ${loginShellLauncher} "$shell"
      if [[ -x /usr/sbin/restorecon ]]; then
        /usr/sbin/restorecon -F "$shell"
      fi
      ${pkgs.gnugrep}/bin/grep -Fqx "$shell" /etc/shells \
        || printf '%s\n' "$shell" >> /etc/shells
      /usr/sbin/usermod --shell "$shell" ${username}

      # Existing sessions can retain the old SHELL value, so keep that path as
      # a forwarding shim without declaring it as a valid login shell.
      legacy_shell=/usr/local/bin/nixconf-nu
      /usr/bin/install -m 0755 ${legacyShellLauncher} "$legacy_shell"
      if [[ -x /usr/sbin/restorecon ]]; then
        /usr/sbin/restorecon -F "$legacy_shell"
      fi
      /usr/bin/sed -i '\|^/usr/local/bin/nixconf-nu$|d' /etc/shells
      for group in ${lib.escapeShellArgs nativeUserGroups}; do
        /usr/bin/getent group "$group" >/dev/null \
          && /usr/sbin/usermod --append --groups "$group" ${username}
      done
      /usr/bin/rm -f /etc/profile.d/nixconf-niri.sh

      /usr/sbin/visudo --check --file /etc/sudoers.d/nixconf
      if [[ -x /usr/sbin/restorecon ]]; then
        /usr/sbin/restorecon -RF \
          /etc/chromium/policies/managed \
          /etc/helium/policies/managed \
          /etc/polkit-1/rules.d \
          /etc/sudoers.d \
          /etc/systemd/zram-generator.conf \
          /etc/tmpfiles.d/nixconf-journal.conf \
          /etc/tmpfiles.d/nixconf-pam.conf
      fi

      /usr/bin/hostnamectl set-hostname alma
      /usr/bin/timedatectl set-timezone America/Montreal
      /usr/bin/systemctl set-default multi-user.target
      /usr/bin/systemctl daemon-reload

      if [[ -f $previous_services ]]; then
        while IFS= read -r service; do
          [[ -z $service ]] && continue
          if ! ${pkgs.gnugrep}/bin/grep -Fxq "$service" ${serviceManifest}; then
            /usr/bin/systemctl disable --now "$service"
          fi
        done < "$previous_services"
      fi
      while IFS= read -r service; do
        [[ -z $service ]] || /usr/bin/systemctl enable --now "$service"
      done < ${serviceManifest}
      /usr/bin/install -m 0644 ${serviceManifest} "$previous_services.new"
      /usr/bin/mv -f "$previous_services.new" "$previous_services"

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

      /usr/sbin/sysctl --system
      /usr/bin/systemctl restart systemd-journald.service
      /usr/bin/journalctl --flush
      /usr/bin/systemctl try-restart nix-daemon.service
      /usr/bin/systemctl start dev-zram0.swap
      ${gpuSetup}/bin/non-nixos-gpu-setup
    '';
  };
}
