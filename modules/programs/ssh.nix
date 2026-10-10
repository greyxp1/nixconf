{inputs, ...}: {
  flake.wrappers.openssh = {...}: {
    install.modules.nixos = {
      wrappers.openssh.enable = true;
      services.openssh = {
        enable = true;
        openFirewall = true;
        startWhenNeeded = true;
      };
      programs.ssh.startAgent = true;
    };
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
