{inputs, ...}: {
  imports = [inputs.nix-secrets.nixosModules.default];

  security.nix-secrets = {
    enable = true;
    storage = ../../secrets;
    storagePath = "/home/grey/Projects/nixconf/secrets";
    # The installer restores this key, so a reinstalled host decrypts its secrets on first boot.
    identityPaths = ["/persistent/secrets/age.key"];
    recipientAliases.grey = "age1usgdmt83jnvnecv8lrcn8n7nz4zer4z3nq8ndmrxpa38gt6s8afsc7nfxe";
    defaultRecipients = ["grey"];
  };
}
