{
  flake.nixosModules.sops = {config, inputs, ...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    users = {
      users.grey.hashedPasswordFile = config.sops.secrets.grey-password.path;
      mutableUsers = false;
    };

    sops = {
      defaultSopsFile = ./secrets.yaml;
      age.keyFile = "/persistent/etc/sops/age/keys.txt";
      secrets = {
        grey-password.neededForUsers = true;
        git-ssh-key = {
          owner = "grey";
          path = "/run/secrets/git-ssh-key";
        };
      };
    };
  };
}
