{
  services.openssh = {
    enable = true;
    openFirewall = true;
    startWhenNeeded = true;
  };

  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host *
        AddKeysToAgent yes
        IdentitiesOnly yes
      Host github.com gitlab.com codeberg.org
        User git
        IdentityFile ~/.ssh/id_ed25519
    '';
  };

  preservation.preserveAt."/persistent".files = [
    {
      file = "/etc/ssh/ssh_host_ed25519_key";
      how = "symlink";
      configureParent = true;
    }
    {
      file = "/etc/ssh/ssh_host_rsa_key";
      how = "symlink";
      configureParent = true;
    }
  ];
}
