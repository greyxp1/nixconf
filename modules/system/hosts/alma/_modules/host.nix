{
  homeDirectory,
  username,
}: {
  lib,
  pkgs,
  ...
}: let
  inherit (import ./inventory.nix {inherit username;}) disabledServices;
in {
  imports = [
    (import ./files.nix {inherit username;})
    (import ./reconcile.nix {inherit username;})
  ];

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.allowUnfree = true;
  };

  system-manager = {
    allowAnyDistro = true;
    preActivationAssertions.alma = {
      enable = true;
      script = ''
        source /etc/os-release
        if [[ ''${ID:-} != almalinux ]]; then
          echo "The alma System Manager configuration requires AlmaLinux." >&2
          exit 1
        fi
        if [[ ! -x /usr/bin/dnf || ! -x /usr/bin/systemctl ]]; then
          echo "Alma's dnf and systemctl commands are required." >&2
          exit 1
        fi
      '';
    };
  };

  # The host account already exists. Userborn is deliberately disabled:
  # its imported Debian-oriented system group IDs do not match Alma's.
  security.enableWrappers = false;
  services.userborn.enable = false;
  users = {
    groups.${username}.gid = 1000;
    users.${username} = {
      isNormalUser = true;
      uid = 1000;
      group = username;
      home = homeDirectory;
      shell = pkgs.nushell;
    };
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  # Only the immutable system profile belongs in the boot path. Package
  # and Home Manager reconciliation run explicitly after a switch.
  systemd = {
    targets.system-manager.wants = ["system-manager-path.service"];
    maskedUnits = ["NetworkManager-wait-online.service"] ++ disabledServices;
    services."home-manager-${username}" = {
      wantedBy = lib.mkForce [];
      environment.PATH = lib.mkForce "/etc/profiles/per-user/${username}/bin:/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin";
    };
  };
}
