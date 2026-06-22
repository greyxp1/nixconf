{...}: {
  flake.nixosModules.ssh = {...}: {
    home-manager.users.grey = {...}: {
      services.ssh-agent.enable = true;
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {AddKeysToAgent = "yes";};
          "github.com" = {IdentityFile = "~/.ssh/id_ed25519";};
        };
      };
    };

    vaultix.secrets.ssh-key = {
      file = ../../secrets/ssh.age;
      path = "/home/grey/.ssh/id_ed25519";
      owner = "grey";
      mode = "600";
    };

    system.activationScripts.ssh-dir = {
      text = "install -d -m 700 -o grey -g users /home/grey/.ssh";
      deps = ["users"];
    };

    services.openssh = {
      enable = true;
      openFirewall = false;
    };
  };
}
