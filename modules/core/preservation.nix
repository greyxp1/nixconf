{inputs, ...}: {
  imports = [inputs.preservation.nixosModules.preservation];
  systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["size=4G" "mode=755"];
    };
    "/nix".neededForBoot = true;
    "/persistent".neededForBoot = true;
  };

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
}
