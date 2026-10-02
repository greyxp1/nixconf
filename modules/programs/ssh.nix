{inputs, ...}: {
  flake.nixosModules.ssh = {
    imports = [inputs.self.wrappers.openssh.install];
    wrappers.openssh.enable = true;
    services.openssh = {
      enable = true;
      openFirewall = false;
      startWhenNeeded = true;
    };
    programs.ssh.startAgent = true;
  };
  flake.wrappers.openssh = {wlib, ...}: {
    imports = [wlib.wrapperModules.openssh];
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        IdentitiesOnly = "yes";
      };
      "github.com gitlab.com codeberg.org" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
