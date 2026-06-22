#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/greyxp1/nixconf.git"
WORK_DIR="/tmp/nixconf"
HOST="${1:-}"

SUBSTITUTERS=(
  "https://cache.nixos.org"
  "https://nix-community.cachix.org"
  "https://niri-nix.cachix.org"
  "https://noctalia.cachix.org"
  "https://attic.xuyh0120.win/lantian"
  "https://cache.garnix.io"
  "https://catppuccin.cachix.org"
)

TRUSTED_KEYS=(
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  "niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0="
  "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
  "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
  "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
  "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
)

NIX_OPTS=(
  --option download-buffer-size 536870912
  --option substituters   "${SUBSTITUTERS[*]}"
  --option trusted-public-keys "${TRUSTED_KEYS[*]}"
)

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
  echo "  [0] desktop  — Nvidia, CachyOS kernel, Secure Boot"
  echo "  [1] vm       — QEMU/SPICE, standard kernel"
  echo "  [2] generic  — portable hardware, standard kernel"
  read -rp "Choice: " n
  case "$n" in
    0) HOST=desktop ;; 1) HOST=vm ;; 2) HOST=generic ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac
fi
[[ "$HOST" =~ ^(desktop|vm|generic)$ ]] || { echo "Unknown host: $HOST"; exit 1; }

trap 'sudo swapoff -a 2>/dev/null || true; sudo umount -R /mnt 2>/dev/null || true' EXIT

echo "==> Fetching config..."
rm -rf "$WORK_DIR" && git clone -q "$REPO" "$WORK_DIR"
exec < /dev/tty

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
  read -rp "Choice (WILL BE WIPED): " i
  DEV="/dev/${DISKS[$i]}"
fi

# Write device — single source of truth for both diskoConfigurations and custom.disk.device
DEV_FINAL=$(by_id "$DEV")
echo "\"$DEV_FINAL\"" > "$WORK_DIR/modules/system/hosts/$HOST/_device.nix"
echo "==> Using device: $DEV_FINAL"

# Two-step install: disko formats the disk and activates swap first, so that
# nixos-install can use it. disko-install builds the entire closure into RAM
# before touching the disk, which OOMs on low-memory VMs.
echo "==> Formatting ($HOST)..."
sudo nix run \
  --extra-experimental-features "nix-command flakes" \
  "${NIX_OPTS[@]}" \
  'github:nix-community/disko/latest' -- \
  --flake "$WORK_DIR#$HOST" \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  2>&1 | grep -E "^(error|Error|warning|Warning|==>)" || true

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
sudo chown -R 1000:1000 /mnt/home/grey/nixconf

echo "==> Done! Rebooting..."
sudo reboot
