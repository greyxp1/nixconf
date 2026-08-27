{username}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cache = import ../_cache.nix;
  inherit (import ./inventory.nix {inherit username;}) storeScriptUnits;
in {
  environment.etc =
    {
      # systemd is not allowed to follow unit symlinks into the Nix store
      # under Alma's SELinux policy, so install managed units as copies.
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
      "nix/nix.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          experimental-features = nix-command flakes
          auto-optimise-store = true
          !include nix.custom.conf
        '';
      };
      "nix/nix.custom.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          trusted-users = root @wheel
          max-jobs = 2
          cores = 6
          warn-dirty = false
          extra-substituters = ${lib.concatStringsSep " " cache.substituters}
          extra-trusted-public-keys = ${lib.concatStringsSep " " cache.trusted-public-keys}
        '';
      };
      "selinux/config" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          SELINUX=disabled
          SELINUXTYPE=targeted
        '';
      };
      "sudoers.d/nixconf" = {
        mode = "0440";
        replaceExisting = true;
        text = "%wheel ALL=(ALL:ALL) NOPASSWD: ALL\n";
      };
      "polkit-1/rules.d/50-nixconf-udisks2.rules" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          polkit.addRule(function(action, subject) {
            if (subject.isInGroup("wheel") && action.id.startsWith("org.freedesktop.udisks2.")) {
              return polkit.Result.YES;
            }
          });
        '';
      };
      "systemd/journald.conf.d/nixconf.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          [Journal]
          Storage=persistent
          SystemMaxUse=500M
          MaxFileSec=1week
        '';
      };
      "systemd/system/getty@tty1.service.d/autologin.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          [Service]
          ExecStart=
          ExecStart=-/sbin/agetty --autologin ${username} --noclear %I $TERM
        '';
      };
      "systemd/system/nix-daemon.service.d/nixconf.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          [Service]
          CPUSchedulingPolicy=idle
          IOSchedulingClass=idle
        '';
      };
      "sysctl.d/90-nixconf.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          vm.swappiness=100
          vm.page-cluster=0
        '';
      };
      "systemd/zram-generator.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          [zram0]
          zram-size = ram / 2
          compression-algorithm = zstd
          swap-priority = 5
        '';
      };
      "tmpfiles.d/nixconf-pam.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = ''
          d /run/wrappers 0755 root root -
          d /run/wrappers/bin 0755 root root -
          L+ /run/wrappers/bin/unix_chkpwd - - - - /usr/sbin/unix_chkpwd
        '';
      };
      "tmpfiles.d/nixconf-journal.conf" = {
        mode = "0644";
        replaceExisting = true;
        text = "d /var/log/journal 2755 root systemd-journal -\n";
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
