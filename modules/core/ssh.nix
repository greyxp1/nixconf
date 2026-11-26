{config, lib, ...}: {
  # Drop with alma: the nix-secrets.enable guards here, since only alma disables nix-secrets.
  security.nix-secrets.secrets = lib.mkIf config.security.nix-secrets.enable {
    "git/ssh-key".owner = "grey";
  };

  programs.ssh = {
    startAgent = true;
    # Drop with alma/laptop: their names on the tailnet Host line.
    extraConfig = ''
      Host *
        AddKeysToAgent yes
        IdentitiesOnly yes
      # Tailscale SSH, so tools like nix copy and nh reach the other hosts.
      Host desktop server laptop alma
        HostName %h.tail1785c.ts.net.
        ProxyCommand tailscale nc %h %p
        UserKnownHostsFile ~/.config/tailscale/ssh_known_hosts
        StrictHostKeyChecking yes
        UpdateHostKeys no
      Host github.com gitlab.com codeberg.org
        User git
        IdentityFile ${if config.security.nix-secrets.enable
          then config.security.nix-secrets.secrets."git/ssh-key".path
          else "~/.ssh/id_ed25519"}
    '';
  };
}
