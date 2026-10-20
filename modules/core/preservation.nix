{inputs, ...}: {
  imports = [inputs.preservation.nixosModules.preservation];
  environment.variables.TMPDIR = "/persistent/tmp";
  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      directories = [
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
        {
          directory = "/var/lib/systemd";
          inInitrd = true;
        }
        "/var/log"
      ];
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];
    };
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["size=4G" "mode=755"];
    };
    "/nix".neededForBoot = true;
    "/persistent".neededForBoot = true;
  };

  systemd = {
    suppressedSystemUnits = ["systemd-machine-id-commit.service"];
    tmpfiles.rules = ["d /persistent/tmp 1777 root root 7d"];
  };
}
