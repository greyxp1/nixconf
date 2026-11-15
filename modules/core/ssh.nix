{
  programs.ssh = {
    startAgent = true;
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
        IdentityFile ~/.ssh/id_ed25519
    '';
  };
}
