{ inputs, ... }: {
  flake.nixosModules.impermanence = { ... }: {
    imports = [ inputs.preservation.nixosModules.preservation ];
    preservation = {
      enable = true;
      preserveAt."/persistent" = {
        directories = [
          # inInitrd required: uid/gid allocations must survive reboots and
          # be available before userspace activation scripts run.
          { directory = "/var/lib/nixos"; inInitrd = true; }
          "/var/lib/NetworkManager" # saved wifi connections
          "/var/lib/bluetooth" # paired BT devices
          "/var/lib/sbctl" # Secure Boot keys (desktop only; harmless no-op elsewhere)
          "/var/log" # persistent logs
        ];
        files = [
          # inInitrd required: machine-id is read by systemd-journald and
          # dbus before any userspace activation can run.
          { file = "/etc/machine-id"; inInitrd = true; }
        ];
      };
    };
  };
}
