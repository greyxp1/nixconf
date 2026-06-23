{...}: let
  gitKey = "/home/grey/nixconf/git-ssh/id_ed25519";
  gitPubKey = "/home/grey/nixconf/git-ssh/id_ed25519.pub";
  gitIdentity = {
    User = "git";
    IdentityFile = "~/.ssh/id_ed25519";
  };
in {
  flake.nixosModules.ssh = {pkgs, ...}: {
    home-manager.users.grey = {...}: {
      services.ssh-agent.enable = true;
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            AddKeysToAgent = "yes";
            IdentitiesOnly = "yes";
          };
          "github.com" = gitIdentity;
          "gitlab.com" = gitIdentity;
          "codeberg.org" = gitIdentity;
        };
      };
    };

    systemd.tmpfiles.settings.ssh-dir."/home/grey/.ssh".d = {
      mode = "0700";
      user = "grey";
      group = "users";
    };

    system.activationScripts.git-ssh-key.text = ''
      if [ -f "${gitKey}" ]; then
        ${pkgs.coreutils}/bin/install -D -m 0600 -o grey -g users "${gitKey}" /home/grey/.ssh/id_ed25519
      fi

      if [ -f "${gitPubKey}" ]; then
        ${pkgs.coreutils}/bin/install -D -m 0644 -o grey -g users "${gitPubKey}" /home/grey/.ssh/id_ed25519.pub
      fi
    '';

    services.openssh = {
      enable = true;
      openFirewall = false;
    };
  };
}
