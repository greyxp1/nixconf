{
  config,
  inputs,
  lib,
  nixos,
  pkgs,
  ...
}: {
  imports = [../../../core/secrets.nix];
  # System Manager uses the systemd service and lacks NixOS's users/groups hooks.
  disabledModules = ["${inputs.nix-secrets}/nix/nixos/activate/activationScripts.nix"];

  security.nix-secrets = {
    identityPaths = lib.mkForce ["/var/lib/nix-secrets/age.key"];
    defaultRecipients = lib.mkForce ["alma"];
    recipientAliases.alma = (import ../../../../secrets/cliproxyapi/recipients.nix).alma;
    secrets."cliproxyapi/client-key" = {
      inherit (nixos.security.nix-secrets.secrets."cliproxyapi/client-key") owner path recipients;
    };
  };

  # Alma already has its native accounts when the regular activation runs.
  systemd.services.nix-secrets-activate-before-users.enable = false;
  systemd.services.nix-secrets-activate = {
    before = ["sysinit.target"];
    unitConfig.RequiresMountsFor = config.security.nix-secrets.identityPaths;
    # nix-secrets-activate swaps .nix-secrets with baseDir via RENAME_EXCHANGE, which requires baseDir to exist.
    serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p -m 0755 /run/nix-secrets";
  };
}
