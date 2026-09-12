{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  loginShellLauncher = pkgs.writeText "nixconf-zsh" ''
    #!/bin/sh
    if [ -x /run/system-manager/sw/bin/zsh ]; then
      exec /run/system-manager/sw/bin/zsh --login "$@"
    fi
    echo "The declarative Zsh is unavailable; starting Alma Bash." >&2
    exec /bin/bash -l "$@"
  '';
in {
  environment.etc = {
    "sudoers.d/nixconf" = {
      mode = "0440";
      replaceExisting = true;
      text = "%wheel ALL=(ALL:ALL) NOPASSWD: ALL\n";
    };
    "systemd/system/getty@tty1.service.d/autologin.conf" = {
      mode = "0644";
      replaceExisting = true;
      text = ''
        [Unit]
        Wants=system-manager-path.service
        After=system-manager-path.service

        [Service]
        ExecStart=
        ExecStart=-/sbin/agetty --autologin ${username} --noclear %I $TERM
      '';
    };
  };
  systemd.tmpfiles.rules = [
    "d /run/wrappers 0755 root root -"
    "d /run/wrappers/bin 0755 root root -"
    "L+ /run/wrappers/bin/unix_chkpwd - - - - /usr/sbin/unix_chkpwd"
  ];
  alma.activation.login = ''
    unix_chkpwd=/usr/sbin/unix_chkpwd
    if [[ ! -x $unix_chkpwd \
      || $(/usr/bin/stat -c %U "$unix_chkpwd") != root \
      || ! -u $unix_chkpwd ]]; then
      echo "$unix_chkpwd must exist, be owned by root, and be setuid" >&2
      exit 1
    fi
    shell=/usr/local/bin/nixconf-zsh
    zsh=/run/system-manager/sw/bin/zsh
    if [[ ! -x $zsh ]]; then
      echo "System Manager's Zsh is missing at $zsh" >&2
      exit 1
    fi
    /usr/bin/install -d -m 0755 /usr/local/bin
    /usr/bin/install -m 0755 ${loginShellLauncher} "$shell"
    if [[ -x /usr/sbin/restorecon ]]; then
      /usr/sbin/restorecon -F "$shell"
    fi
    ${pkgs.gnugrep}/bin/grep -Fqx "$shell" /etc/shells \
      || printf '%s\n' "$shell" >> /etc/shells
    /usr/sbin/usermod --shell "$shell" ${username}

    for group in ${lib.escapeShellArgs config.alma.userGroups}; do
      /usr/bin/getent group "$group" >/dev/null \
        && /usr/sbin/usermod --append --groups "$group" ${username}
    done
    /usr/bin/rm -f /etc/profile.d/nixconf-niri.sh /usr/local/bin/nixconf-nu
    /usr/bin/sed -i '\|^/usr/local/bin/nixconf-nu$|d' /etc/shells

    /usr/sbin/visudo --check --file /etc/sudoers.d/nixconf
  '';
}
