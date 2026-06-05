{...}: {
  flake.nixosModules.shell = {pkgs, ...}: {
    programs.fish.enable = true;
    users.users.grey.shell = pkgs.fish;
    home-manager.users.grey = {...}: {
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set -g fish_greeting
          function fish_postexec --on-event fish_postexec
            set -q __fish_skip_newline; or echo
            set -eg __fish_skip_newline
          end
          function fish_prompt
            starship prompt --status $status --pipestatus $pipestatus
          end
          bind \cl 'printf \\033[3J; command clear; commandline -f repaint'
        '';

        functions = {
          ls = ''
            eza --long --icons --git --group-directories-first --time-style=relative --header $argv
            set -g __fish_skip_newline 1
          '';
          clear = ''
            printf '\033[3J]'
            command clear
            set -g __fish_skip_newline 1
          '';
          cat = "bat --paging=never $argv";
          rebuild = "nh os switch";
          update = "nh os switch --update";
          home = "sudo systemctl restart home-manager-grey.service";
          clean = "nh clean all";
          optimise = "nix store optimise -v";
          tree = "lstr -g --icons --git-status";
          treell = "lstr -a -s -p --icons";
          treei = "lstr interactive -g --icons --git-status";

          enroll = ''
            if not test -f ~/.age/key.txt
              echo "Paste your AGE-SECRET-KEY then press Ctrl+D:"
              mkdir -p ~/.age
              cat > ~/.age/key.txt
              chmod 600 ~/.age/key.txt
            end

            # Rebuild first — ragenix uses the age key to decrypt and place ~/.ssh/id_ed25519
            nh os switch

            set -l host (hostname)
            set -l new_key (awk '{print $1" "$2}' /etc/ssh/ssh_host_ed25519_key.pub)
            set -l secrets ~/nixconf/secrets/secrets.nix

            if grep -q "# $host" $secrets
              sed -i "s|\"ssh-ed25519 [^\"]*\" # $host|\"$new_key\" # $host|" $secrets
            else
              awk -v e="    \"$new_key\" # $host" '/^\s*\];/ { print e } { print }' \
                $secrets > /tmp/_s.nix && mv /tmp/_s.nix $secrets
            end

            cd ~/nixconf
            ragenix --rules secrets/secrets.nix -r -i ~/.age/key.txt
            git add secrets/
            git commit -m "chore: enroll $host"
            git push
          '';
        };
      };
    };
  };
}
