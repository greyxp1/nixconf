{
  inputs,
  pkgs,
  ...
}: let
  helium = inputs.self.wrappers.helium.wrap {inherit pkgs;};
  heliumPolicy = pkgs.writeText "helium-policy.json" (builtins.toJSON helium.configuration.policies);
  drivers = pkgs.buildEnv {
    name = "alma-gpu-drivers";
    paths = with pkgs; [mesa libglvnd libvdpau-va-gl intel-media-driver];
  };
in {
  environment.etc = {
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
  };
  systemd.tmpfiles.rules = ["d /var/log/journal 2755 root systemd-journal -"];
  alma.activation.policy = ''
    install_helium_policy() {
      local target=$1
      /usr/bin/install -d -m 0755 "$(/usr/bin/dirname "$target")"
      if [[ ! -f $target ]] || ! /usr/bin/cmp -s ${heliumPolicy} "$target"; then
        if /usr/bin/pgrep -x helium >/dev/null; then
          echo "Refusing to change Helium policy while Helium is running: $target" >&2
          exit 1
        fi
        /usr/bin/install -m 0644 ${heliumPolicy} "$target"
        if [[ -x /usr/sbin/restorecon ]]; then
          /usr/sbin/restorecon -F "$target"
        fi
      fi
    }
    install_helium_policy /etc/chromium/policies/managed/helium.json
    install_helium_policy /etc/helium/policies/managed/helium.json
  '';
  alma.activation.finish = ''
    for directory in /home/grey/.config /home/grey/.local/share /home/grey/.codex /home/grey/.ssh; do
      [[ -d $directory ]] || continue
      while IFS= read -r -d "" link; do
        case "$(/usr/bin/readlink "$link")" in
          /nix/store/*-home-manager-files/*) /usr/bin/rm "$link" ;;
        esac
      done < <(/usr/bin/find "$directory" -type l -print0)
    done
    /usr/bin/systemctl disable --now home-manager-grey.service 2>/dev/null || true
    if [[ -x /usr/sbin/restorecon ]]; then
      /usr/sbin/restorecon -RF \
        /etc/chromium/policies/managed /etc/helium/policies/managed \
        /etc/polkit-1/rules.d /etc/sudoers.d /etc/systemd/zram-generator.conf
    fi
    /usr/sbin/sysctl --system
    /usr/bin/systemctl restart systemd-journald.service
    /usr/bin/journalctl --flush
    /usr/bin/systemctl try-restart nix-daemon.service
    /usr/bin/systemctl start dev-zram0.swap
    /usr/bin/ln -sfn ${drivers} /run/opengl-driver
  '';
}
