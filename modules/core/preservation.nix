{inputs, ...}: {
  imports = [inputs.preservation.nixosModules.preservation];
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

  boot.tmp.cleanOnBoot = true;

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["size=4G" "mode=755"];
    };
    "/nix".neededForBoot = true;
    "/persistent".neededForBoot = true;
    "/tmp" = {
      device = "/persistent/tmp";
      fsType = "none";
      options = ["bind"];
    };
  };

  systemd = {
    suppressedSystemUnits = ["systemd-machine-id-commit.service"];
    tmpfiles.rules = ["d /persistent/tmp 1777 root root 7d"];
  };
}
