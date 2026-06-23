{...}: let
  gitKey = "/home/grey/nixconf/git-ssh/id_ed25519";
  gitPubKey = "/home/grey/nixconf/git-ssh/id_ed25519.pub";
in {
  flake.nixosModules.ssh = {pkgs, ...}: let
    sshConfig = pkgs.writeText "grey-ssh-config" ''
      Host *
        AddKeysToAgent yes
        IdentitiesOnly yes

      Host github.com gitlab.com codeberg.org
        User git
        IdentityFile ~/.ssh/id_ed25519
    '';
  in {
    home-manager.users.grey = {...}: {
      services.ssh-agent.enable = true;
    };

    systemd.tmpfiles.settings.ssh-dir."/home/grey/.ssh".d = {
      mode = "0700";
      user = "grey";
      group = "users";
    };

    system.activationScripts.git-ssh-key.text = ''
      ${pkgs.coreutils}/bin/install -d -m 0700 -o grey -g users /home/grey/.ssh

      ${pkgs.coreutils}/bin/install -m 0600 -o grey -g users ${sshConfig} /home/grey/.ssh/config

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
