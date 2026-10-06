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
  flake.wrappers.openssh = {...}: {
    imports = ["${inputs.wrapper-openssh}/wrapperModules/o/openssh/module.nix"];
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
