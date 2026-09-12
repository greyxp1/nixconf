{
  config,
  pkgs,
  username,
  ...
}: let
  heliumPolicy =
    pkgs.writeText "helium-policy.json"
    config.home-manager.users.${username}.programs.helium.finalPolicyJson;
  gpuSetup = config.home-manager.users.${username}.targets.genericLinux.gpu.setupPackage;
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
    ${gpuSetup}/bin/non-nixos-gpu-setup
  '';
}
