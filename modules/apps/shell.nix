{ ... }:
{
  flake.nixosModules.shell =
    { pkgs, ... }:
    {
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

      home-manager.users.grey =
        { ... }:
        {
          programs.fish = {
            enable = true;
            interactiveShellInit = ''
              set -g fish_greeting
              set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
              set -gx PAGER "bat -p"
              function ls; nu -c "ls $argv"; end
              function cat; bat --paging=never $argv; end
              bind \cl 'clear; commandline -f repaint'
            '';

            functions = {
              rebuild = "nh os switch";
              update = "nh os switch --update";
              home = "sudo systemctl restart home-manager-grey.service";
              clean = "nh clean all";
              cdi = "__zoxide_zi";
              tree = "lstr -g --icons --git-status";
              treell = "lstr -a -s -p --icons";
              treei = "lstr interactive -g --icons --git-status";

              clear = ''
                printf '\033[3J'
                command clear
                commandline -f repaint
              '';
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
            settings = {
              add_newline = false;
              aws.disabled = true;
              gcloud.disabled = true;
              line_break.disabled = true;
            };
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
          ];
        };
    };
}
