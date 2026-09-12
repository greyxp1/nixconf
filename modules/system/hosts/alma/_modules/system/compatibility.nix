{
  config,
  gid,
  homeDirectory,
  lib,
  pkgs,
  primaryGroup,
  uid,
  username,
  ...
}: let
  almaMajors = builtins.attrNames config.alma.extraPackagesByMajor;
  supportedAlmaMajors = lib.concatStringsSep "|" almaMajors;
  supportedAlmaMajorsText = lib.concatStringsSep " or " almaMajors;
  storeScriptUnits = ["alma-host.service" "home-manager-${username}.service" "system-manager-path.service"];
in {
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

  # A fresh Alma installation still enforces SELinux until the first reboot.
  # Keep systemd units local and launch store scripts through native Bash.
  environment.etc =
    {
      "systemd/system".enable = lib.mkForce false;
      "systemd/system/multi-user.target.d/system-manager.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          [Unit]
          Wants=system-manager.target
          After=system-manager.target
        '';
      };
    }
    // lib.mapAttrs' (
      name: unit:
        lib.nameValuePair "systemd/system/${name}" {
          source =
            if builtins.elem name storeScriptUnits
            then
              pkgs.runCommand "alma-${name}" {} ''
                ${pkgs.gnused}/bin/sed \
                  -E 's|^(ExecStart=)(/nix/store/)|\1/bin/bash ${lib.optionalString (name == "home-manager-${username}.service") "-el "}\2|' \
                  ${unit.unit}/${name} > "$out"
              ''
            else "${unit.unit}/${name}";
          mode = "0644";
          replaceExisting = true;
        }
    ) (lib.filterAttrs (_: unit: unit.enable) config.systemd.units);
}
