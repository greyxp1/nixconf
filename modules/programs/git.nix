{ ... }: {
  flake.nixosModules.git = { ... }: {
    home-manager.users.grey = { pkgs, ... }: {
      programs.git.enable = true;
      programs.git.settings = {
        credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
        credential.credentialStore = "secretservice";
        init.defaultBranch = "main";
        help.autocorrect = 1;
        column.ui = "auto";
        pull.rebase = true;
        branch.autosetuprebase = "always";
        push.autoSetupRemote = true;
        diff.algorithm = "histogram";
        merge.conflictstyle = "zdiff3";
        fetch.prune = true;
        fetch.all = true;
        user.name = "greyxp1";
        user.email = "greyxp999@gmail.com";
      };
      programs.delta.enable = true;
      programs.delta.options = {
        side-by-side = true;
        line-numbers = true;
      };
    };
  };
}
