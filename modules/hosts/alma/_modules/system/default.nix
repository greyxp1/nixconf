{
  config,
  lib,
  ...
}: let
  cfg = config.alma;
in {
  imports = [./compatibility.nix];

  options.alma =
    lib.genAttrs [
      "packages"
      "services"
      "userGroups"
      "kernelArguments"
      "removedKernelArguments"
    ] (_:
      lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      })
    // lib.genAttrs ["hostName" "timeZone" "defaultTarget"] (_:
      lib.mkOption {
        type = lib.types.str;
      })
    // {
      extraPackagesByMajor = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      };
      packageGroups = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
      };
      activation = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        internal = true;
      };
    };

  config.systemd.services.alma-host = {
    description = "Reconcile the AlmaLinux host";
    after = ["system-manager-path.service"];
    requires = ["system-manager-path.service"];
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "15min";
    };
    script = ''
      set -euo pipefail
      export LC_ALL=C
      export PATH=/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
      state_dir=/var/lib/nixconf
      pending_initramfs="$state_dir/initramfs-pending"
      /usr/bin/install -d -m 0755 "$state_dir"

      ${cfg.activation.policy}
      ${cfg.activation.bootPrepare}
      ${cfg.activation.packages}
      ${cfg.activation.bootImages}
      ${cfg.activation.login}
      ${cfg.activation.services}
      ${cfg.activation.virtualisation}
      ${cfg.activation.kernelArguments}
      ${cfg.activation.finish}
    '';
  };
}
