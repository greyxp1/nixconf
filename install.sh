#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/greyxp1/nixconf.git"
HOST="${1:-}"
WORK_DIR=$(mktemp -d -t nixconf.XXXXXX)

cleanup() {
  sudo umount -R /mnt 2>/dev/null || true
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

# Returns the most stable device path for a given block device:
# prefers /dev/disk/by-id/<name> (excluding partition entries),
# falls back to the raw /dev/... path if no by-id symlink exists (e.g. VirtIO).
by_id() {
  local real
  real=$(readlink -f "$1")
  while IFS= read -r link; do
    [[ "$(readlink -f "$link")" == "$real" ]] && echo "$link" && return
  done < <(find /dev/disk/by-id/ -maxdepth 1 -type l ! -name '*-part*' 2>/dev/null)
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

echo "==> Fetching config..."
git clone -q "$REPO" "$WORK_DIR"

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

[[ -d /sys/firmware/efi/efivars ]] || { echo "UEFI required"; exit 1; }

# Disk selection — exclude loop devices (-e 7) and the ISO boot disk
ISO_DISK=$(findmnt -n -o SOURCE /iso 2>/dev/null | xargs -r lsblk -no PKNAME 2>/dev/null || true)
mapfile -t DISKS < <(lsblk -dn -o NAME,TYPE -e 7 | awk '$2=="disk"{print $1}' | grep -v "^${ISO_DISK}$" || true)
[[ ${#DISKS[@]} -gt 0 ]] || { echo "No disks found"; exit 1; }

if [[ ${#DISKS[@]} -eq 1 ]]; then
  DEV="/dev/${DISKS[0]}"
  echo "==> Disk: $DEV $(lsblk -dno SIZE,MODEL "$DEV")"
else
  echo "Select a disk to install on:"
  for i in "${!DISKS[@]}"; do
    printf "  [%d] /dev/%s  %s  %s\n" "$i" "${DISKS[$i]}" \
      "$(lsblk -dno SIZE "/dev/${DISKS[$i]}")" "$(lsblk -dno MODEL "/dev/${DISKS[$i]}")"
  done
  read -rp "Choice (WILL BE WIPED): " i < /dev/tty
  [[ "$i" =~ ^[0-9]+$ ]] && ((i < ${#DISKS[@]})) || { echo "Invalid choice"; exit 1; }
  DEV="/dev/${DISKS[$i]}"
fi

DEV_FINAL=$(by_id "$DEV")
read -rp "Type WIPE to erase $DEV_FINAL: " confirm < /dev/tty
[[ "$confirm" == "WIPE" ]] || { echo "Aborted"; exit 1; }

# Write the device consumed directly by the host's Disko configuration.
echo "\"$DEV_FINAL\"" > "$WORK_DIR/modules/system/hosts/$HOST/_device.nix"
echo "==> Using device: $DEV_FINAL"

# Two-step install: disko formats the disk and activates swap first, so that
# nixos-install can use it. disko-install builds the entire closure into RAM
# before touching the disk, which OOMs on low-memory VMs.
echo "==> Formatting ($HOST)..."
sudo nix run \
  --extra-experimental-features "nix-command flakes" \
  "${NIX_OPTS[@]}" \
  "$WORK_DIR#disko" -- \
  --flake "$WORK_DIR#$HOST" \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  2>&1 | sed -nE '/^(error|Error|warning|Warning|==>)/p'

echo "==> Installing NixOS ($HOST)..."
sudo nixos-install \
  --root /mnt \
  --flake "$WORK_DIR#$HOST" \
  --no-root-passwd \
  "${NIX_OPTS[@]}"

# The copied config already has the correct device baked in for future disko runs.
echo "==> Copying nixconf..."
sudo mkdir -p /mnt/home/grey
sudo cp -rT "$WORK_DIR" /mnt/home/grey/nixconf
sudo chown -R 1000:100 /mnt/home/grey/nixconf

echo "==> Done! Rebooting..."
sudo reboot
