#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/greyxp1/nixconf.git"
WORK_DIR="/tmp/nixconf"
HOST="${1:-}"

# ── Host selection ────────────────────────────────────────────────────────────
if [[ -z "$HOST" || "$HOST" == "--help" || "$HOST" == "-h" ]]; then
  echo "Select a host to install:"
  echo "  [0] desktop  — full desktop, Nvidia, CachyOS kernel, Secure Boot"
  echo "  [1] vm       — full desktop, QEMU/SPICE guest tools, standard kernel"
  echo "  [2] generic  — full desktop, portable hardware config, standard kernel"
  read -rp "Choice (number): " HOST_CHOICE
  case "$HOST_CHOICE" in
    0) HOST="desktop" ;;
    1) HOST="vm"      ;;
    2) HOST="generic" ;;
    *) echo "ERROR: Invalid choice."; exit 1 ;;
  esac
fi

case "$HOST" in
  desktop|vm|generic) ;;
  *)
    echo "ERROR: Unknown host '$HOST'. Choose: desktop, vm, or generic."
    exit 1 ;;
esac

# ── Cleanup on exit ───────────────────────────────────────────────────────────
cleanup() { sudo umount -R /mnt 2>/dev/null || true; }
trap cleanup EXIT

# ── 1. Clone config ───────────────────────────────────────────────────────────
echo "==> Fetching config ($HOST)..."
rm -rf "$WORK_DIR"
git clone -q "$REPO" "$WORK_DIR"
cd "$WORK_DIR"

exec < /dev/tty

# ── 2. Require UEFI ───────────────────────────────────────────────────────────
if [[ ! -d /sys/firmware/efi/efivars ]]; then
  echo "ERROR: UEFI firmware required. BIOS/Legacy is not supported."
  exit 1
fi
echo "==> Firmware: UEFI"

# ── 3. Disk selection ─────────────────────────────────────────────────────────
ISO_DISK=$(findmnt -n -o SOURCE /iso 2>/dev/null | xargs -r lsblk -no PKNAME 2>/dev/null || true)

mapfile -t DISK_NAMES < <(
  lsblk -dn -o NAME,TYPE -e 7 \
    | awk '$2=="disk"{print $1}' \
    | grep -v "^${ISO_DISK}$" \
  || true
)
[[ ${#DISK_NAMES[@]} -eq 0 ]] && { echo "ERROR: No eligible disks found."; exit 1; }

if [[ ${#DISK_NAMES[@]} -eq 1 ]]; then
  DEV="/dev/${DISK_NAMES[0]}"
  echo "==> Disk: $DEV  $(lsblk -dno SIZE "$DEV")  $(lsblk -dno MODEL "$DEV")"
else
  echo "Available disks:"
  for i in "${!DISK_NAMES[@]}"; do
    printf "  [%d] /dev/%s  %s  %s\n" "$i" \
      "${DISK_NAMES[$i]}" \
      "$(lsblk -dno SIZE  "/dev/${DISK_NAMES[$i]}")" \
      "$(lsblk -dno MODEL "/dev/${DISK_NAMES[$i]}")"
  done
  read -rp "DANGER: This will WIPE the selected disk. Choose (number): " CHOICE
  [[ -z "${DISK_NAMES[$CHOICE]+x}" ]] && { echo "ERROR: Invalid choice."; exit 1; }
  DEV="/dev/${DISK_NAMES[$CHOICE]}"
fi

# ── 4. Partition and format with disko ────────────────────────────────────────
echo "==> Partitioning and formatting $DEV..."
sudo nix --extra-experimental-features "nix-command flakes" \
  run 'github:nix-community/disko/latest' -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  --flake "$WORK_DIR#$HOST" \
  --disk main "$DEV" 2>&1 | grep -E "^(error|Error|warning|Warning|==>) " || true

# Wait for udev to finish creating device symlinks, then activate swap
echo "==> Activating swap..."
sudo udevadm settle
SWAP_DEV=$(sudo blkid -t TYPE=swap -o device 2>/dev/null | head -1)
if [[ -n "$SWAP_DEV" ]]; then
  sudo swapon "$SWAP_DEV"
  echo "==> Swap: $(free -h | awk '/Swap/{print $2}') total"
else
  echo "WARNING: No swap partition found, proceeding without swap"
fi

# ── 5. Install ────────────────────────────────────────────────────────────────
echo "==> Installing NixOS ($HOST)..."
sudo nixos-install \
  --root /mnt \
  --flake "$WORK_DIR#$HOST" \
  --no-root-passwd \
  --option substituters "https://cache.nixos.org https://nix-community.cachix.org https://niri.cachix.org https://noctalia.cachix.org https://attic.xuyh0120.win/lantian https://cache.garnix.io https://catppuccin.cachix.org" \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964= noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4= lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g= catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="

# ── 6. Persist config on installed system ─────────────────────────────────────
sudo cp -rT "$WORK_DIR" /mnt/home/grey/nixconf
sudo chown -R 1000:1000 /mnt/home/grey/nixconf

echo "==> Done! Rebooting..."
sudo reboot
