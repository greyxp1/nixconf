#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/greyxp1/nixconf.git"
HOST="${1:-}"
WORK_DIR=$(mktemp -d -t nixconf.XXXXXX)
INSTALL_MANAGES_MNT=false

cleanup() {
  if [[ "$INSTALL_MANAGES_MNT" == true ]]; then
    sudo umount -R /mnt 2>/dev/null || true
  fi
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

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
if [[ -z "$HOST" ]]; then
  echo "Select a host:"
  echo "  [0] desktop  — Nvidia, gaming, virtualization"
  echo "  [1] vm       — QEMU/SPICE, standard kernel"
  echo "  [2] generic  — portable hardware, standard kernel"
  read -rp "Choice: " n < /dev/tty
  case "$n" in
    0) HOST=desktop ;; 1) HOST=vm ;; 2) HOST=generic ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac
fi
[[ "$HOST" =~ ^(desktop|vm|generic)$ ]] || { echo "Unknown host: $HOST"; exit 1; }

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
  [[ "$i" =~ ^[0-9]+$ ]] && ((i < ${#DISKS[@]})) || { echo "Invalid choice"; exit 1; }
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
