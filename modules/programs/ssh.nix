{inputs, ...}: {
  flake.nixosModules.ssh = {...}: {
    imports = [inputs.ragenix.nixosModules.default];
    environment.systemPackages = [inputs.ragenix.packages.x86_64-linux.default];
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

    age = {
      secrets.ssh-key = {
        file = ../../secrets/ssh.age;
        path = "/home/grey/.ssh/id_ed25519";
        owner = "grey";
        mode = "600";
        symlink = false;
      };

      identityPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/home/grey/.age/key.txt"
      ];
    };

    system = {
      activationScripts.ssh-dir = {
        text = "install -d -m 700 -o grey -g users /home/grey/.ssh";
        deps = ["users"];
      };
    };

    services.openssh = {
      enable = true;
      openFirewall = false;
    };
  };
}
