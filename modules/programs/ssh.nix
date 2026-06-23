_: let
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
    home-manager.users.grey = {lib, ...}: {
      services.ssh-agent.enable = true;

      home.activation.gitSshKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${pkgs.coreutils}/bin/install -d -m 0700 "$HOME/.ssh"

        ${pkgs.coreutils}/bin/install -m 0600 ${sshConfig} "$HOME/.ssh/config"

        if [ -f "${gitKey}" ]; then
          ${pkgs.coreutils}/bin/install -m 0600 "${gitKey}" "$HOME/.ssh/id_ed25519"
        fi

        if [ -f "${gitPubKey}" ]; then
          ${pkgs.coreutils}/bin/install -m 0644 "${gitPubKey}" "$HOME/.ssh/id_ed25519.pub"
        fi
      '';
    };

    services.openssh = {
      enable = true;
      openFirewall = false;
    };
  };
}
