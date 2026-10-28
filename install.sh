#!/usr/bin/env bash
set -euo pipefail
umask 022

REPO="${NIXCONF_REPO:-https://github.com/greyxp1/nixconf.git}"
HOST=${1:-}
if [[ -z $HOST ]]; then
  PS3="Select a host: "
  select HOST in desktop generic laptop server; do
    [[ -n $HOST ]] && break
  done < /dev/tty
fi
case "$HOST" in
  desktop|generic|laptop|server) ;;
  *) echo "Unknown host: $HOST" >&2; exit 1 ;;
esac
if [[ $HOST != laptop && ! -d /sys/firmware/efi/efivars ]]; then
  echo "UEFI required for $HOST" >&2
  exit 1
fi

# Exclude loop devices and the ISO boot disk.
ISO_DISK=$(findmnt -nro SOURCE /iso 2>/dev/null | xargs -r lsblk -snro NAME,TYPE 2>/dev/null | awk '$2 == "disk" { print $1 }' || true)
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

read -rp "Type WIPE to erase $DEV: " confirm < /dev/tty
[[ $confirm == WIPE ]] || { echo "Aborted"; exit 1; }
PASSWORD_HASH=$(mkpasswd --method=yescrypt < /dev/tty)

WORK_DIR=$(mktemp -d -t nixconf.XXXXXX)
INSTALL_MANAGES_MNT=false
target_mounts() {
  findmnt -rn -o TARGET | awk '$0 == "/mnt" || index($0, "/mnt/") == 1'
}
cleanup() {
  if [[ $INSTALL_MANAGES_MNT == true ]]; then
    target_mounts | sort -r | xargs -r sudo umount || true
    sudo rm -f /dev/nixos-disk
  fi
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

git clone -q --depth 1 "$REPO" "$WORK_DIR"
cache_attr() {
  nix eval --extra-experimental-features nix-command --raw --impure --expr \
    "builtins.concatStringsSep \" \" (import $WORK_DIR/modules/core/_cache.nix).\"$1\""
}
NIX_OPTS=(
  --option extra-experimental-features 'nix-command flakes'
  --option download-buffer-size 536870912
  --option extra-substituters "$(cache_attr substituters)"
  --option extra-trusted-public-keys "$(cache_attr trusted-public-keys)"
)

if [[ $HOST == laptop ]]; then
  GRUB_DEVICE=$(nix eval "${NIX_OPTS[@]}" --raw "$WORK_DIR#nixosConfigurations.laptop.config.boot.loader.grub.devices" --apply builtins.head)
  [[ $DEV -ef $GRUB_DEVICE ]] || { echo "The laptop bootloader requires $GRUB_DEVICE" >&2; exit 1; }
fi
if [[ -n $(target_mounts) ]]; then
  echo "Refusing to replace existing mounts under /mnt" >&2
  exit 1
fi
sudo ln -s "$DEV" /dev/nixos-disk
INSTALL_MANAGES_MNT=true
# Format first so nixos-install builds on disk instead of in the ISO's RAM.
sudo nix run "${NIX_OPTS[@]}" "$WORK_DIR#disko" -- \
  --flake "$WORK_DIR#$HOST" --mode destroy,format,mount --yes-wipe-all-disks
sudo install -d -m700 /mnt/persistent/passwords
# /tmp bind-mounts this at boot, before tmpfiles could create it.
sudo install -d -m1777 /mnt/persistent/tmp
printf '%s\n' "$PASSWORD_HASH" | sudo tee /mnt/persistent/passwords/grey >/dev/null
sudo chmod 600 /mnt/persistent/passwords/grey
unset PASSWORD_HASH
sudo nixos-install "${NIX_OPTS[@]}" --root /mnt --flake "$WORK_DIR#$HOST" --no-root-passwd --no-channel-copy
sudo install -d -o 1000 -g 100 /mnt/home/grey/Projects
sudo cp -rT "$WORK_DIR" /mnt/home/grey/Projects/nixconf
sudo chown -R 1000:100 /mnt/home/grey/Projects/nixconf
cleanup
trap - EXIT
sudo reboot
