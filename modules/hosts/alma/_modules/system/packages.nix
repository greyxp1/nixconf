{
  config,
  lib,
  pkgs,
  ...
}: let
  dnfManifests = lib.mapAttrs (major: packages:
    pkgs.writeText "alma-${major}-dnf-packages" (
      lib.concatStringsSep "\n" packages + "\n"
    ))
  (lib.mapAttrs (_: extra: config.alma.packages ++ extra) config.alma.extraPackagesByMajor);
  selectDnfManifest = lib.concatStringsSep "\n  " (
    lib.mapAttrsToList (major: manifest: "${major}) dnf_manifest=${manifest} ;;")
    dnfManifests
  );
  dnfGroupManifest = pkgs.writeText "alma-dnf-groups" (
    lib.concatStringsSep "\n" (lib.mapAttrsToList (id: name: "${id}|${name}") config.alma.packageGroups) + "\n"
  );
in {
  environment.etc = {
    "dnf/dnf.conf" = {
      mode = "0644";
      replaceExisting = true;
      text = ''
        [main]
        gpgcheck=1
        installonly_limit=2
        clean_requirements_on_remove=True
        best=True
        skip_if_unavailable=False
      '';
    };
  };
  alma.activation.packages = ''
    source /etc/os-release
    alma_major=''${VERSION_ID%%.*}
    case "$alma_major" in
      ${selectDnfManifest}
      *)
        echo "Unsupported AlmaLinux major version: ''${VERSION_ID:-unknown}" >&2
        exit 1
        ;;
    esac

    previous_packages="$state_dir/dnf-packages"
    previous_groups="$state_dir/dnf-groups"

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
    # Keep this work pending across interrupted installs and later failures.
    if [[ $rebuild_initramfs == true ]]; then
      /usr/bin/install -m 0644 /dev/null "$pending_initramfs"
    fi
    if (( ''${#missing[@]} )); then
      /usr/bin/dnf install -y "''${missing[@]}"
    fi
    # Protect native packages owned by this configuration from group
    # removal, even when DNF originally installed them as group members.
    if (( ''${#declared[@]} )); then
      /usr/bin/dnf mark install "''${declared[@]}"
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
      # Erase the declared set together so its internal dependencies do not
      # block removal. RPM still refuses dependencies from retained packages.
      /usr/bin/rpm -e "''${removed[@]}"
    fi
    /usr/bin/install -m 0644 "$dnf_manifest" "$previous_packages.new"
    /usr/bin/mv -f "$previous_packages.new" "$previous_packages"
  '';
}
