{inputs, ...}: {
  flake.nixosModules = {
    git = {pkgs, ...}: {
      environment.systemPackages = [pkgs.gh pkgs.delta];
      programs.git = {
        enable = true;
        config = {
          init.defaultBranch = "main";
          column.ui = "auto";
          pull.rebase = true;
          push.autoSetupRemote = true;
          diff.algorithm = "histogram";
          merge.conflictstyle = "zdiff3";
          fetch.prune = true;
          credential = {
            "https://github.com".helper = ["" "${pkgs.gh}/bin/gh auth git-credential"];
            "https://gist.github.com".helper = ["" "${pkgs.gh}/bin/gh auth git-credential"];
          };
          url = {
            "git@github.com:".pushInsteadOf = "https://github.com/";
            "git@gitlab.com:".pushInsteadOf = "https://gitlab.com/";
            "git@codeberg.org:".pushInsteadOf = "https://codeberg.org/";
          };
          user = {
            name = "greyxp1";
            email = "greyxp999@gmail.com";
          };
          include.path = "${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.delta}/catppuccin.gitconfig";
          delta = {
            features = "catppuccin-mocha";
            side-by-side = true;
            line-numbers = true;
          };
        };
      };
    };

    lazygit = {
      programs.lazygit = {
        enable = true;
        settings = {
          notARepository = "skip";
          gui.theme = {
            activeBorderColor = ["#cba6f7" "bold"];
            inactiveBorderColor = ["#a6adc8"];
            searchingActiveBorderColor = ["#f9e2af"];
            optionsTextColor = ["#89b4fa"];
            selectedLineBgColor = ["#313244"];
            inactiveViewSelectedLineBgColor = ["#6c7086"];
            cherryPickedCommitFgColor = ["#cba6f7"];
            cherryPickedCommitBgColor = ["#45475a"];
            markedBaseCommitFgColor = ["#89b4fa"];
            markedBaseCommitBgColor = ["#f9e2af"];
            unstagedChangesColor = ["#f38ba8"];
            defaultFgColor = ["#cdd6f4"];
            authorColors."*" = "#b4befe";
          };
        };
      };
    };
  };
}
