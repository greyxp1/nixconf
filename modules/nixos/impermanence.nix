{ inputs, ... }: {
  flake.nixosModules.impermanence = { ... }: {
    imports = [ inputs.preservation.nixosModules.preservation ];

    preservation = {
      enable = true;
      preserveAt."/persistent" = {
        directories = [
          { directory = "/var/lib/nixos"; inInitrd = true; } # uid/gid allocations
          "/var/lib/NetworkManager"                          # saved wifi connections
          "/var/lib/bluetooth"                               # paired devices
          "/var/lib/sbctl"                                   # Secure Boot keys
          "/var/log"
        ];
        files = [
          { file = "/etc/machine-id"; inInitrd = true; }
        ];
      };
    };
  };
}
