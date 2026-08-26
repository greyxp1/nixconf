#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/greyxp1/nixconf.git"

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
  local backup_branch
  local branch
  local previous_head
  local remote_head

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
  previous_head=$(git -C "$repo_dir" rev-parse HEAD)
  git -C "$repo_dir" fetch --prune origin main
  remote_head=$(git -C "$repo_dir" rev-parse FETCH_HEAD)

  if [[ $previous_head == "$remote_head" ]]; then
    return
  fi
  if ! git -C "$repo_dir" merge-base --is-ancestor "$previous_head" "$remote_head"; then
    backup_branch="alma-installer-backup/${previous_head:0:12}"
    if ! git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$backup_branch"; then
      git -C "$repo_dir" branch "$backup_branch" "$previous_head"
    fi
    echo "==> Preserved rewritten local history as $backup_branch"
  fi
  git -C "$repo_dir" reset --hard "$remote_head"
}

build_alma_system_config() {
  local repo_dir="$1"
  local username="$2"
  local uid="$3"
  local gid="$4"
  local primary_group="$5"
  local home_directory="$6"

  NIX_PATH='' \
  NIXCONF_REPO="$repo_dir" \
  NIXCONF_USERNAME="$username" \
  NIXCONF_UID="$uid" \
  NIXCONF_GID="$gid" \
  NIXCONF_PRIMARY_GROUP="$primary_group" \
  NIXCONF_HOME="$home_directory" \
    nix build --impure --no-link --print-out-paths \
      --file "$repo_dir/modules/system/hosts/alma/_build.nix"
}

install_alma() {
  local gid
  local home_directory
  local nix_profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  local primary_group
  local repo_dir
  local system_config
  local system_manager
  local uid
  local username

  [[ $EUID -ne 0 ]] || {
    echo "Run the Alma installer as the account that will use this system, not root." >&2
    exit 1
  }
  username=$(id -un)
  uid=$(id -u)
  gid=$(id -g)
  primary_group=$(id -gn)
  home_directory=$(getent passwd "$username" | /usr/bin/cut -d: -f6)
  if [[ ! $username =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*$ \
    || ! $primary_group =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*$ \
    || $home_directory != /* \
    || ! -d $home_directory ]]; then
    echo "The current native account has unsupported identity data." >&2
    exit 1
  fi
  repo_dir="$home_directory/Projects/nixconf"
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ ${ID:-} != almalinux || ! ${VERSION_ID:-} =~ ^(9|10)(\.|$) ]]; then
    echo "The Alma installer supports only AlmaLinux 9 and 10." >&2
    exit 1
  fi
  if ! id -nG "$username" | /usr/bin/tr ' ' '\n' | /usr/bin/grep -Fqx wheel; then
    echo "$username must belong to the wheel group." >&2
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
    "$repo_dir" "$username" "$uid" "$gid" "$primary_group" "$home_directory")
  "$system_manager/bin/system-manager" register --store-path "$system_config" --sudo
  "$system_manager/bin/system-manager" activate --store-path "$system_config" --sudo
  [[ ! -L result ]] || /usr/bin/rm -f result
  restart_and_wait_for_unit alma-host.service 900
  restart_and_wait_for_unit "home-manager-$username.service" 300

  echo "Alma setup for $username is complete. Verify Niri on tty1 before rebooting; tty2 remains the recovery console."
}

configure_alma_nix() {
  local cache_file="$1/modules/system/hosts/alma/_cache.nix"
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

# Returns the most stable device path for a given block device:
# prefers /dev/disk/by-id/<name> (excluding partition entries),
# falls back to the raw /dev/... path if no by-id symlink exists (e.g. VirtIO).
by_id() {
  local link
  for link in /dev/disk/by-id/*; do
    [[ "$link" != *-part* && "$link" -ef "$1" ]] && echo "$link" && return
  done
  echo "$1"
}

# Host selection
echo "Select a host:"
echo "  [0] desktop  — Nvidia, gaming, virtualization"
echo "  [1] vm       — QEMU/SPICE, standard kernel"
echo "  [2] generic  — portable hardware, standard kernel"
echo "  [3] alma     — AlmaLinux with System Manager"
read -rp "Choice: " n < /dev/tty
case "$n" in
  0) HOST=desktop ;; 1) HOST=vm ;; 2) HOST=generic ;; 3) HOST=alma ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

if [[ "$HOST" == alma ]]; then
  install_alma
  exit
fi

WORK_DIR=$(mktemp -d -t nixconf.XXXXXX)
INSTALL_MANAGES_MNT=false

cleanup() {
  if [[ "$INSTALL_MANAGES_MNT" == true ]]; then
    sudo umount -R /mnt 2>/dev/null || true
  fi
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

PASSWORD_HASH=$(mkpasswd --method=yescrypt)

[[ -d /sys/firmware/efi/efivars ]] || { echo "UEFI required"; exit 1; }

# Disk selection — exclude loop devices (-e 7) and the ISO boot disk
ISO_DISK=$(findmnt -n -o SOURCE /iso 2>/dev/null | xargs -r lsblk -no PKNAME 2>/dev/null || true)
mapfile -t DISKS < <(lsblk -dn -o NAME,TYPE -e 7 | awk -v iso="$ISO_DISK" '$2 == "disk" && $1 != iso { print $1 }')
[[ ${#DISKS[@]} -gt 0 ]] || { echo "No disks found"; exit 1; }

if [[ ${#DISKS[@]} -eq 1 ]]; then
  DEV="/dev/${DISKS[0]}"
  echo "==> Disk: $DEV $(lsblk -dno SIZE,MODEL "$DEV")"
else
  echo "Select a disk to install on:"
  for i in "${!DISKS[@]}"; do
    printf "  [%d] /dev/%s  %s\n" "$i" "${DISKS[$i]}" \
      "$(lsblk -dno SIZE,MODEL "/dev/${DISKS[$i]}")"
  done
  read -rp "Choice (WILL BE WIPED): " i < /dev/tty
  if ! [[ "$i" =~ ^[0-9]+$ ]] || ((i >= ${#DISKS[@]})); then
    echo "Invalid choice"
    exit 1
  fi
  DEV="/dev/${DISKS[$i]}"
fi

DEV_FINAL=$(by_id "$DEV")
read -rp "Type WIPE to erase $DEV_FINAL: " confirm < /dev/tty
[[ "$confirm" == "WIPE" ]] || { echo "Aborted"; exit 1; }

echo "==> Fetching config..."
git clone -q "$REPO" "$WORK_DIR"

# Write the device consumed directly by the host's Disko configuration.
echo "\"$DEV_FINAL\"" > "$WORK_DIR/modules/system/hosts/$HOST/_device.nix"
echo "==> Using device: $DEV_FINAL"

cache_attr() {
  nix eval --raw \
    --impure \
    --extra-experimental-features "nix-command" \
    --expr "builtins.concatStringsSep \" \" (import $WORK_DIR/modules/system/_cache.nix).\"$1\""
}

NIX_OPTS=(
  --option download-buffer-size 536870912
  --option substituters "$(cache_attr substituters)"
  --option trusted-public-keys "$(cache_attr trusted-public-keys)"
)

# Disko formats and mounts first so nixos-install builds directly on the target;
# disko-install can OOM low-memory VMs by building the closure in RAM.
echo "==> Formatting ($HOST)..."
if findmnt -rn -o TARGET | awk '$0 == "/mnt" || index($0, "/mnt/") == 1 { found=1 } END { exit !found }'; then
  echo "Refusing to replace existing mounts under /mnt"
  exit 1
fi
INSTALL_MANAGES_MNT=true
sudo nix run \
  --extra-experimental-features "nix-command flakes" \
  "${NIX_OPTS[@]}" \
  "$WORK_DIR#disko" -- \
  --flake "$WORK_DIR#$HOST" \
  --mode destroy,format,mount \
  --yes-wipe-all-disks

sudo install -d -m700 /mnt/persistent/passwords
printf '%s\n' "$PASSWORD_HASH" | sudo tee /mnt/persistent/passwords/grey >/dev/null
sudo chmod 600 /mnt/persistent/passwords/grey
unset PASSWORD_HASH

echo "==> Installing NixOS ($HOST)..."
sudo nixos-install \
  --root /mnt \
  --flake "$WORK_DIR#$HOST" \
  --no-root-passwd \
  "${NIX_OPTS[@]}"

# The copied config already has the correct device baked in for future disko runs.
echo "==> Copying nixconf..."
sudo install -d -o 1000 -g 100 /mnt/home/grey/Projects
sudo cp -rT "$WORK_DIR" /mnt/home/grey/Projects/nixconf
sudo chown -R 1000:100 /mnt/home/grey/Projects/nixconf

echo "==> Done! Rebooting..."
sudo reboot
