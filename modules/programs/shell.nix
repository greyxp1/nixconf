{ ... }: {
  flake.nixosModules.shell = { pkgs, ... }: {
    programs.nh = {
      enable = true;
      flake = "/home/grey/nixconf";
      clean = {
        enable = true;
        extraArgs = "--keep-since 2d --keep 3";
      };
    };

    programs.fish.enable = true;
    users.users.grey.shell = pkgs.fish;
    home-manager.users.grey = { ... }: {
      home.sessionVariables = {
        MANPAGER = "sh -c 'col -bx | bat -l man -p'";
        PAGER = "bat -p";
      };

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set -g fish_greeting
          set -g __fish_skip_newline 1

          function fish_postexec --on-event fish_postexec
            set -g __fish_skip_newline 0
            contains -- (string split -m1 ' ' -- $argv[1])[1] ls clear && set -g __fish_skip_newline 1
          end

          function fish_prompt
            test "$__fish_skip_newline" = 0 && echo
            set -g __fish_skip_newline 0
            starship prompt --status $status --pipestatus $pipestatus
          end

          bind \cl 'set -g __fish_skip_newline 1; clear; commandline -f repaint'
          function ls; nu -c "ls $argv"; end
        '';

        functions = {
          cat = "bat --paging=never $argv";
          clear = ''
            printf '\033[3J'
            command clear
          '';
          rebuild = "nh os switch";
          update = "nh os switch --update";
          home = "sudo systemctl restart home-manager-grey.service";
          clean = "nh clean all";
          tree = "lstr -g --icons --git-status";
          treell = "lstr -a -s -p --icons";
          treei = "lstr interactive -g --icons --git-status";
        };
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = [ "--cmd cd" ];
      };

      programs.starship = {
        enable = true;
        enableFishIntegration = true;
        settings = let theme = fromTOML (builtins.readFile (builtins.fetchurl {
          url = "https://raw.githubusercontent.com/CoryCharlton/starship-configuration/master/starship.toml";
          sha256 = "sha256:0g0fs3j7rrk7v099xqni935c3w480nzr0i04ahav5riw03c1hxrd";
        })); in theme // { format = builtins.replaceStrings [ "\n$character" ] [ "$character" ] theme.format; add_newline = false; };
      };

      programs.bottom = {
        enable = true;
        settings = {
          flags = {
            group_processes = true;
            process_memory_as_value = true;
            case_sensitive = false;
            regex = true;
          };
        };
      };

      home.packages = with pkgs; [
        curl
        lstr
        bat
        fastfetch
        zip
        unzip
        wget
        codex
        nerd-fonts.jetbrains-mono
        fzf
        nushell
        dash
        tldr
      ];
    };
  };
}
