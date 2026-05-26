#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/greyxp1/nixconf.git"
WORK_DIR="/tmp/nixconf"
HOST="${1:-}"

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

echo "==> Fetching config..."
rm -rf "$WORK_DIR" && git clone -q "$REPO" "$WORK_DIR"
exec < /dev/tty

[[ -d /sys/firmware/efi/efivars ]] || { echo "UEFI required"; exit 1; }

# Disk selection
ISO_DISK=$(findmnt -n -o SOURCE /iso 2>/dev/null | xargs -r lsblk -no PKNAME 2>/dev/null || true)
mapfile -t DISKS < <(lsblk -dn -o NAME,TYPE -e 7 | awk '$2=="disk"{print $1}' | grep -v "^${ISO_DISK}$" || true)
[[ ${#DISKS[@]} -gt 0 ]] || { echo "No disks found"; exit 1; }

if [[ ${#DISKS[@]} -eq 1 ]]; then
  DEV="/dev/${DISKS[0]}"
  echo "==> Disk: $DEV $(lsblk -dno SIZE,MODEL "$DEV")"
else
  for i in "${!DISKS[@]}"; do
    printf "  [%d] /dev/%s  %s  %s\n" "$i" "${DISKS[$i]}" \
      "$(lsblk -dno SIZE "/dev/${DISKS[$i]}")" "$(lsblk -dno MODEL "/dev/${DISKS[$i]}")"
  done
  read -rp "Choice (WILL BE WIPED): " i
  DEV="/dev/${DISKS[$i]}"
fi

# Format, install, and write bootloader in one step.
# --disk main overrides disko.devices.disk.main.device via mkVMOverride (priority 10),
# which beats mkForce (50), so custom.disk.device in disk.nix is correctly overridden.
echo "==> Installing NixOS ($HOST) on $DEV..."
sudo nix run \
  --extra-experimental-features "nix-command flakes" \
  'github:nix-community/disko/latest#disko-install' -- \
  --flake "$WORK_DIR#$HOST" \
  --disk main "$DEV" \
  --write-efi-boot-entries \
  --mount-point /mnt \
  --option substituters "https://cache.nixos.org https://nix-community.cachix.org https://niri.cachix.org https://noctalia.cachix.org https://attic.xuyh0120.win/lantian https://cache.garnix.io https://catppuccin.cachix.org" \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964= noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4= lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g= catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="

# disko-install unmounts /mnt on exit. Remount @home to copy nixconf
# so `nh` and rebuilds work out of the box after first boot.
echo "==> Copying nixconf..."
mkdir -p /mnt
sudo mount -t btrfs -o subvol=@home,compress=zstd,noatime LABEL=nixos /mnt
sudo cp -rT "$WORK_DIR" /mnt/grey/nixconf
sudo chown -R 1000:1000 /mnt/grey/nixconf
sudo umount /mnt

echo "==> Done! Rebooting..."
sudo reboot
