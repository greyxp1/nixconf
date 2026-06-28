_: {
  flake.homeModules.git = _: {
    programs = {
      git = {
        enable = true;
        settings = {
          init.defaultBranch = "main";
          column.ui = "auto";
          core.sshCommand = "ssh -F ~/.ssh/config";
          pull.rebase = true;
          branch.autosetuprebase = "always";
          push.autoSetupRemote = true;
          diff.algorithm = "histogram";
          merge.conflictstyle = "zdiff3";
          fetch = {
            prune = true;
            all = true;
          };
          url = {
            "git@github.com:".insteadOf = "https://github.com/";
            "git@gitlab.com:".insteadOf = "https://gitlab.com/";
            "git@codeberg.org:".insteadOf = "https://codeberg.org/";
          };
          user = {
            name = "greyxp1";
            email = "greyxp999@gmail.com";
          };
        };
      };

      delta = {
        enable = true;
        options = {
          side-by-side = true;
          line-numbers = true;
        };
      };
    };
  };
}
