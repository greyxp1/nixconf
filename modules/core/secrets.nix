{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  secrets = config.security.nix-secrets;
  defaultRecipient = builtins.head secrets.defaultRecipients;
in {
  imports = [inputs.nix-secrets.nixosModules.default];

  security.nix-secrets = {
    enable = true;
    # The regular activation script can decrypt secrets before local accounts are created.
    activate.method =
      if builtins.any (entry: entry.enable && entry.neededForUsers) (
        builtins.attrValues secrets.secrets ++ builtins.attrValues secrets.templates
      )
      then "activationScripts"
      else "systemd";
    storage = ../../secrets;
    storagePath = "/home/grey/Projects/nixconf/secrets";
    identityPaths = ["/persistent/secrets/age.key"];
    recipientAliases.grey = "age1usgdmt83jnvnecv8lrcn8n7nz4zer4z3nq8ndmrxpa38gt6s8afsc7nfxe";
    defaultRecipients = ["grey"];
  };

  systemd.services.nix-secrets-activate = lib.mkIf (secrets.enable && secrets.activate.enable && secrets.activate.method == "systemd") {
    before = ["systemd-tmpfiles-setup.service"];
    unitConfig.ConditionPathExists = map (path: "|${path}") secrets.identityPaths;
  };

  environment.systemPackages = lib.mkIf secrets.enable [
    (pkgs.writeShellApplication {
      name = "restore-secrets";
      runtimeInputs = [pkgs.age pkgs.coreutils pkgs.systemd];
      text = ''
        if (( EUID != 0 )); then
          echo "Run sudo restore-secrets." >&2
          exit 1
        fi
        key=${lib.escapeShellArg (builtins.head secrets.identityPaths)}
        if [[ -e $key || -L $key ]]; then
          echo "An age key is already installed." >&2
          exit 1
        fi
        identity=$(systemd-ask-password "Paste your age key")
        if ! recipient=$(printf '%s\n' "$identity" | age-keygen -y 2>/dev/null) ||
          [[ $recipient != ${lib.escapeShellArg (secrets.recipientAliases.${defaultRecipient} or defaultRecipient)} ]]; then
          echo "This key cannot decrypt your nixconf secrets." >&2
          exit 1
        fi
        install -d -m700 -- "$(dirname -- "$key")"
        umask 077
        temporary=$(mktemp -- "$key.XXXXXXXX")
        trap 'rm -f -- "$temporary"' EXIT
        printf '%s\n' "$identity" > "$temporary"
        ln -T -- "$temporary" "$key"
        echo "Age key installed. Reboot to restore your secrets."
      '';
    })
  ];
}
