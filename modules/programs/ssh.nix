{
  flake.nixosModules.ssh = {
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
  };
}
