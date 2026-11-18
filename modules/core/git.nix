{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  githubHosts = config.security.nix-secrets.secrets."github/hosts";
in {
  security.nix-secrets.secrets = lib.mkIf config.security.nix-secrets.enable {
    "github/hosts".owner = "grey";
  };
  systemd.user.services.restore-github-credentials = lib.mkIf config.security.nix-secrets.enable {
    description = "Restore GitHub CLI credentials";
    # The user manager reports readiness when basic.target is reached.
    wantedBy = ["basic.target"];
    before = ["basic.target"];
    unitConfig = {
      ConditionPathExists = [githubHosts.path "!%h/.config/gh/hosts.yml"];
      ConditionUser = githubHosts.owner;
      DefaultDependencies = false;
    };
    serviceConfig.Type = "oneshot";
    script = ''
      directory="$HOME/.config/gh"
      mkdir -p -m 0700 -- "$directory"
      temporary=$(mktemp -- "$directory/.hosts.XXXXXXXX")
      trap 'rm -f -- "$temporary"' EXIT
      install -m 0600 -- ${lib.escapeShellArg githubHosts.path} "$temporary"
      ln -T -- "$temporary" "$directory/hosts.yml" || test -e "$directory/hosts.yml"
    '';
  };
  environment.systemPackages = [pkgs.gh pkgs.delta];
  programs = {
    git = {
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

    lazygit = {
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
}
