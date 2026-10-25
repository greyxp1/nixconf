#!/usr/bin/env bash
set -euo pipefail
umask 022

REPO="${NIXCONF_REPO:-https://github.com/greyxp1/nixconf.git}"

use_alma_https_repositories() {
  local repo_file

  for repo_file in /etc/yum.repos.d/almalinux-*.repo; do
    [[ -f $repo_file ]] || continue
    sudo /usr/bin/sed -i \
      -e 's|^mirrorlist=|# mirrorlist=|' \
      -e 's|^# *baseurl=https://repo.almalinux.org/almalinux/|baseurl=https://repo.almalinux.org/almalinux/|' \
      "$repo_file"
  done
}

bootstrap_alma_sudo() {
  local policy_file

  policy_file=$(/usr/bin/mktemp -t nixconf-sudoers.XXXXXX)
  /usr/bin/printf '%s\n' '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >"$policy_file"
  /usr/sbin/visudo --check --file "$policy_file"
  sudo /usr/bin/install -o root -g root -m 0440 \
    "$policy_file" /etc/sudoers.d/nixconf
  /usr/bin/rm -f "$policy_file"

  # Everything after this point must remain unattended-safe, including the
  # privileged System Manager activation after a potentially long Nix build.
  sudo -n /usr/bin/true
}

update_alma_checkout() {
  local repo_dir="$1"
  local branch

  if [[ -n $(git -C "$repo_dir" status --porcelain --untracked-files=all) ]]; then
    echo "Refusing to update a checkout with local changes: $repo_dir" >&2
    echo "Commit or stash those changes, then run the installer again." >&2
    exit 1
  fi

  branch=$(git -C "$repo_dir" symbolic-ref --quiet --short HEAD || true)
  if [[ $branch != main ]]; then
    echo "Refusing to replace the current Git branch '$branch'; expected 'main'." >&2
    exit 1
  fi

  echo "==> Updating existing checkout: $repo_dir"
  git -C "$repo_dir" fetch --prune origin main
  git -C "$repo_dir" rebase FETCH_HEAD
}

build_alma_system_config() {
  local repo_dir="$1"
  local uid="$2"
  local gid="$3"
  local primary_group="$4"

  NIX_PATH='' \
  NIXCONF_UID="$uid" \
  NIXCONF_GID="$gid" \
  NIXCONF_PRIMARY_GROUP="$primary_group" \
    nix build --impure --no-link --print-out-paths \
      --file "$repo_dir/modules/hosts/alma/_build.nix"
}

install_alma() {
  local gid
  local nix_profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  local primary_group
  local repo_dir
  local system_config
  local system_manager
  local uid

  [[ $EUID -ne 0 ]] || {
    echo "Run the Alma installer as the account that will use this system, not root." >&2
    exit 1
  }
  if [[ $(id -un) != grey || $(getent passwd grey | /usr/bin/cut -d: -f6) != /home/grey ]]; then
    echo "Run the Alma installer as grey with home directory /home/grey." >&2
    exit 1
  fi
  uid=$(id -u)
  gid=$(id -g)
  primary_group=$(id -gn)
  if [[ ! $primary_group =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*$ || ! -d /home/grey ]]; then
    echo "The current native account has unsupported identity data." >&2
    exit 1
  fi
  repo_dir="/home/grey/Projects/nixconf"
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ ${ID:-} != almalinux || ! ${VERSION_ID:-} =~ ^(9|10)(\.|$) ]]; then
    echo "The Alma installer supports only AlmaLinux 9 and 10." >&2
    exit 1
  fi
  if ! id -nG grey | /usr/bin/tr ' ' '\n' | /usr/bin/grep -Fqx wheel; then
    echo "grey must belong to the wheel group." >&2
    exit 1
  fi
  sudo -v
  bootstrap_alma_sudo
  use_alma_https_repositories
  rpm --quiet -q git || sudo dnf install -y git

  if [[ ! -e "$nix_profile" ]]; then
    curl -fsSL https://artifacts.nixos.org/nix-installer \
      | sh -s -- install --enable-flakes --no-confirm
  fi
  # shellcheck disable=SC1090
  source "$nix_profile"

  mkdir -p "$(dirname "$repo_dir")"
  if [[ -d "$repo_dir/.git" ]]; then
    update_alma_checkout "$repo_dir"
  elif [[ -e "$repo_dir" ]]; then
    echo "Refusing to replace existing path: $repo_dir" >&2
    exit 1
  else
    git clone "$REPO" "$repo_dir"
  fi

  cd "$repo_dir"
  configure_alma_nix "$repo_dir"
  system_manager=$(nix build --no-link --print-out-paths .#system-manager)
  system_config=$(build_alma_system_config \
    "$repo_dir" "$uid" "$gid" "$primary_group")
  "$system_manager/bin/system-manager" register --store-path "$system_config" --sudo
  "$system_manager/bin/system-manager" activate --store-path "$system_config" --sudo
  [[ ! -L result ]] || /usr/bin/rm -f result
  restart_and_wait_for_unit alma-host.service 900

  echo "Alma setup for grey is complete. Verify Niri on tty1 before rebooting; tty2 remains the recovery console."
}

configure_alma_nix() {
  local cache_file="$1/modules/hosts/alma/_cache.nix"
  local substituters
  local trusted_public_keys

  substituters=$(nix eval --raw --impure --expr \
    "builtins.concatStringsSep \" \" (import $cache_file).substituters")
  trusted_public_keys=$(nix eval --raw --impure --expr \
    "builtins.concatStringsSep \" \" (import $cache_file).trusted-public-keys")

  sudo /usr/bin/install -d -m 0755 /etc/nix
  /usr/bin/printf '%s\n' \
    'trusted-users = root @wheel' \
    'max-jobs = 2' \
    'cores = 6' \
    'warn-dirty = false' \
    "extra-substituters = $substituters" \
    "extra-trusted-public-keys = $trusted_public_keys" \
    | sudo /usr/bin/tee /etc/nix/nix.custom.conf >/dev/null
  /usr/bin/grep -Fqx '!include nix.custom.conf' /etc/nix/nix.conf \
    || /usr/bin/printf '%s\n' '!include nix.custom.conf' \
      | sudo /usr/bin/tee -a /etc/nix/nix.conf >/dev/null
  sudo /usr/bin/systemctl restart nix-daemon.service
}

restart_and_wait_for_unit() {
  local unit="$1"
  local timeout="$2"
  local before_invocation
  local current_invocation
  local deadline
  local queued=false
  local state

  echo "==> Starting $unit..."
  before_invocation=$(sudo /usr/bin/systemctl show \
    --property=InvocationID --value "$unit" 2>/dev/null || true)
  if sudo /usr/bin/systemctl restart --no-block "$unit"; then
    queued=true
  else
    # The queued job can survive a transient system-bus disconnect. Reconnect
    # and identify the new invocation before deciding that it failed.
    deadline=$((SECONDS + 30))
    while ((SECONDS < deadline)); do
      current_invocation=$(sudo /usr/bin/systemctl show \
        --property=InvocationID --value "$unit" 2>/dev/null || true)
      if [[ -n $current_invocation && $current_invocation != "$before_invocation" ]]; then
        queued=true
        break
      fi
      /usr/bin/sleep 1
    done
    if [[ $queued != true ]]; then
      sudo /usr/bin/journalctl --boot --unit "$unit" --no-pager --lines 200
      return 1
    fi
  fi

  deadline=$((SECONDS + timeout))
  while ((SECONDS < deadline)); do
    current_invocation=$(sudo /usr/bin/systemctl show \
      --property=InvocationID --value "$unit" 2>/dev/null || true)
    state=$(sudo /usr/bin/systemctl show \
      --property=ActiveState --value "$unit" 2>/dev/null || true)
    if [[ -n $current_invocation && $current_invocation != "$before_invocation" ]]; then
      case "$state" in
        active)
          echo "==> $unit finished successfully."
          return 0
          ;;
        failed)
          sudo /usr/bin/journalctl --boot --unit "$unit" --no-pager --lines 200
          return 1
          ;;
      esac
    fi
    /usr/bin/sleep 1
  done

  echo "Timed out waiting for $unit." >&2
  sudo /usr/bin/journalctl --boot --unit "$unit" --no-pager --lines 200
  return 1
}

install_alma
