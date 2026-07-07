{
  flake.nixosModules.fish = {pkgs, ...}: {
    programs.fish.enable = true;
    users.users.grey.shell = pkgs.fish;
  };

  flake.homeModules.fish = {pkgs, ...}: {
    programs.fish = {
      enable = true;

      shellAbbrs = {
        rebuild = "nh os switch";
        update = "cd ~/nixconf && tack update && nh os switch";
        home = "sudo systemctl restart home-manager-grey.service";
        clean = "nh clean all --optimise --keep 1";
        ls = "ls --no-filesize";
        ll = "ll --total-size";
        la = "la --no-filesize";
        lla = "la --total-size";
        lt = "lt --no-time --no-filesize";
        llt = "lt --total-size";
        ff = "microfetch";
        lg = "lazygit";
        oc = "opencode";
      };

      functions = {
        clear = "command clear; printf '\\033[3J'";

        fish_user_key_bindings = ''
          bind \r _nl_enter
          bind \cl 'clear; commandline -f repaint'
          bind \t _accept_or_complete
          bind ctrl-j _completion_down
          bind ctrl-k _completion_up
        '';

        _accept_or_complete = ''
          if commandline --showing-suggestion
            commandline -f accept-autosuggestion
          else
            commandline -f complete
          end
        '';

        _completion_down = ''
          commandline --paging-mode
          and commandline -f down-line
          or commandline -f complete
        '';

        _completion_up = ''
          commandline --paging-mode
          and commandline -f up-line
          or commandline -f repaint
        '';

        restore-ssh-key = ''
          mkdir -p ~/.ssh
          chmod 700 ~/.ssh
          cat > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
        '';
      };

      interactiveShellInit = ''
        set -g fish_greeting
        function _nl --on-event fish_postexec; echo; end
        function _nl_enter
          string length -q -- (commandline); or echo
          commandline -f execute
        end
      '';

      plugins = map (pkg: {
        name = pkg.pname;
        inherit (pkg) src;
      }) (with pkgs.fishPlugins; [
        fzf-fish
        done
      ]);
    };
  };
}
