{
  gid,
  homeDirectory,
  primaryGroup,
  uid,
  username,
}: {
  lib,
  pkgs,
  ...
}: let
  inherit
    (import ./inventory.nix {inherit username;})
    disabledServices
    dnfPackagesByMajor
    ;
  almaMajors = lib.sort (a: b: builtins.fromJSON a < builtins.fromJSON b) (
    builtins.attrNames dnfPackagesByMajor
  );
  supportedAlmaMajors = lib.concatStringsSep "|" almaMajors;
  supportedAlmaMajorsText = lib.concatStringsSep " or " almaMajors;
in {
  imports = [
    (import ./files.nix {inherit username;})
    (import ./reconcile.nix {inherit username;})
  ];

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.allowUnfree = true;
  };

  system-manager = {
    allowAnyDistro = true;
    preActivationAssertions.alma = {
      enable = true;
      script = ''
        source /etc/os-release
        if [[ ''${ID:-} != almalinux ]]; then
          echo "The alma System Manager configuration requires AlmaLinux." >&2
          exit 1
        fi
        alma_major=''${VERSION_ID%%.*}
        case "$alma_major" in
          ${supportedAlmaMajors}) ;;
          *)
            echo "Unsupported AlmaLinux major version: ''${VERSION_ID:-unknown}. Expected ${supportedAlmaMajorsText}." >&2
            exit 1
            ;;
        esac
        if [[ ! -x /usr/bin/dnf || ! -x /usr/bin/systemctl ]]; then
          echo "Alma's dnf and systemctl commands are required." >&2
          exit 1
        fi
        account=${lib.escapeShellArg username}
        expected_home=${lib.escapeShellArg homeDirectory}
        if [[ $(/usr/bin/id -u "$account") != ${toString uid} \
          || $(/usr/bin/id -g "$account") != ${toString gid} \
          || $(/usr/bin/id -gn "$account") != ${lib.escapeShellArg primaryGroup} \
          || $(/usr/bin/getent passwd "$account" | /usr/bin/cut -d: -f6) != "$expected_home" ]]; then
          echo "The native account no longer matches the Alma configuration for $account." >&2
          exit 1
        fi
      '';
    };
  };

  # The host account already exists. Userborn is deliberately disabled:
  # its imported Debian-oriented system group IDs do not match Alma's.
  security.enableWrappers = false;
  services.userborn.enable = false;
  users = {
    groups.${primaryGroup}.gid = gid;
    users.${username} = {
      isNormalUser = true;
      inherit uid;
      group = primaryGroup;
      home = homeDirectory;
    };
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/zsh"
    "/share/xdg-desktop-portal"
  ];
  environment.systemPackages = [pkgs.zsh];

  # Only the immutable system profile belongs in the boot path. Package
  # and Home Manager reconciliation run explicitly after a switch.
  systemd = {
    targets.system-manager.wants = ["system-manager-path.service"];
    maskedUnits = ["NetworkManager-wait-online.service"] ++ disabledServices;
    services."home-manager-${username}" = {
      wantedBy = lib.mkForce [];
      environment = {
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${toString uid}/bus";
        PATH = lib.mkForce "/etc/profiles/per-user/${username}/bin:/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin";
        XDG_RUNTIME_DIR = "/run/user/${toString uid}";
      };
    };
  };
}
