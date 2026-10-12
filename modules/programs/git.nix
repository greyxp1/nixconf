{inputs, ...}: {
  flake.nixosModules.git = {pkgs, ...}: {
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
}
