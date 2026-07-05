{
  flake.nixosModules.ssh = {
    services.openssh = {
      enable = true;
      openFirewall = false;
    };
  };

  flake.homeModules.ssh = {
    services.ssh-agent.enable = true;
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
        "github.com gitlab.com codeberg.org" = {
          User = "git";
          IdentityFile = "/run/secrets/git-ssh-key";
        };
      };
    };
  };
}
