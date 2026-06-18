{...}: {
  flake.nixosModules.git = {...}: {
    home-manager.users.grey = {...}: {
      programs = {
        git = {
          enable = true;
          settings = {
            init.defaultBranch = "main";
            column.ui = "auto";
            pull.rebase = true;
            branch.autosetuprebase = "always";
            push.autoSetupRemote = true;
            diff.algorithm = "histogram";
            merge.conflictstyle = "zdiff3";
            fetch = {
              prune = true;
              all = true;
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
  };
}
