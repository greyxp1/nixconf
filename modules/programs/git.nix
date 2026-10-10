{inputs, ...}: {
  flake = {
    wrappers = {
      git = {
        pkgs,
        wlib,
        ...
      }: {
        install.modules.nixos = {pkgs, ...}: {
          imports = [inputs.self.wrappers.delta.install];
          wrappers.git.enable = true;
          wrappers.delta.enable = true;
          environment.systemPackages = [pkgs.gh];
        };
        imports = [wlib.wrapperModules.git];
        settings = {
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
        };
      };

      delta = {
        pkgs,
        wlib,
        ...
      }: {
        imports = [wlib.modules.default];
        package = pkgs.delta;
        flags."--config" = (pkgs.formats.gitIni {}).generate "delta-config" {
          include.path = "${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.delta}/catppuccin.gitconfig";
          delta = {
            features = "catppuccin-mocha";
            side-by-side = true;
            line-numbers = true;
          };
        };
      };
    };
  };
}
