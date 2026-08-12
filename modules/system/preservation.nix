{inputs, ...}: {
  flake.nixosModules.preservation = {
    imports = [inputs.preservation.nixosModules.preservation];
    systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];
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
          "/var/lib/NetworkManager"
          "/var/lib/flatpak"
          "/var/log"
        ];
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
          {
            file = "/etc/ssh/ssh_host_ed25519_key";
            how = "symlink";
            configureParent = true;
          }
          {
            file = "/etc/ssh/ssh_host_rsa_key";
            how = "symlink";
            configureParent = true;
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
  };
}
