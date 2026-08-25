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
    dnfPackages
    kernelArguments
    nativeServices
    ;

  dnfManifest = pkgs.writeText "alma-dnf-packages" (
    lib.concatStringsSep "\n" dnfPackages + "\n"
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
  gpuSetup = config.home-manager.users.${username}.targets.genericLinux.gpu.setupPackage;
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

      state_dir=/var/lib/nixconf
      previous_packages="$state_dir/dnf-packages"
      previous_groups="$state_dir/dnf-groups"
      previous_services="$state_dir/native-services"
      previous_kernel_arguments="$state_dir/kernel-arguments"
      /usr/bin/install -d -m 0755 "$state_dir"

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
      done < ${dnfManifest}
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

      missing_groups=()
      while IFS='|' read -r group_id group_name; do
        [[ -z $group_id ]] && continue
        if [[ ! -f $previous_groups ]] \
          || ! /usr/bin/grep -Fxq "$group_id|$group_name" "$previous_groups"; then
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
          if ! ${pkgs.gnugrep}/bin/grep -Fxq "$package" ${dnfManifest} \
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
      /usr/bin/install -m 0644 ${dnfManifest} "$previous_packages.new"
      /usr/bin/mv -f "$previous_packages.new" "$previous_packages"
      if [[ $rebuild_initramfs == true ]]; then
        /usr/bin/dracut -f --regenerate-all
      fi

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

      shell=/usr/local/bin/nixconf-nu
      nushell=/run/system-manager/sw/bin/nu
      if [[ ! -x $nushell ]]; then
        echo "System Manager's Nushell is missing at $nushell" >&2
        exit 1
      fi
      /usr/bin/install -d -m 0755 /usr/local/bin
      /usr/bin/printf '%s\n' \
        '#!/bin/sh' \
        'exec /run/system-manager/sw/bin/nu --login --interactive "$@"' \
        > "$shell"
      /usr/bin/chmod 0755 "$shell"
      if [[ -x /usr/sbin/restorecon ]]; then
        /usr/sbin/restorecon -F "$shell"
      fi
      ${pkgs.gnugrep}/bin/grep -Fqx "$shell" /etc/shells \
        || printf '%s\n' "$shell" >> /etc/shells
      /usr/sbin/usermod --shell "$shell" ${username}
      for group in wheel video render; do
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
      /usr/bin/install -m 0644 ${kernelArgumentManifest} "$previous_kernel_arguments.new"
      /usr/bin/mv -f "$previous_kernel_arguments.new" "$previous_kernel_arguments"

      /usr/sbin/sysctl --system
      /usr/bin/systemctl restart systemd-journald.service
      /usr/bin/journalctl --flush
      /usr/bin/systemctl try-restart nix-daemon.service
      /usr/bin/systemctl start dev-zram0.swap
      ${gpuSetup}/bin/non-nixos-gpu-setup
    '';
  };
}
