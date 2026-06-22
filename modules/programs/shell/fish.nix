{...}: {
  flake.nixosModules.shell = {pkgs, ...}: {
    programs.fish.enable = true;
    users.users.grey.shell = pkgs.fish;
    home-manager.users.grey = {...}: {
      programs.fish = {
        enable = true;
        shellAliases = {
        };

        shellAbbrs = {
          rebuild = "nh os switch";
          update = "cd ~/nixconf && tack update && nh os switch";
          home = "sudo systemctl restart home-manager-grey.service";
          clean = "nh clean all --optimise --keep-one";
          cat = "bat";

          ls = "ls --no-filesize";
          ll = "ll --total-size";
          la = "la --no-filesize";
          lla = "la --total-size";
          lt = "lt --no-time --no-filesize";
          llt = "lt --total-size";
        };

        functions = {
          clear = "command clear; printf '\\033[3J'";
          fish_user_key_bindings = "bind \\r _nl_enter; bind \\cl 'clear; commandline -f repaint'";
          enroll = ''
            if not test -f ~/.age/key.txt
              echo "Paste your AGE-SECRET-KEY then press Ctrl+D:"
              mkdir -p ~/.age
              cat > ~/.age/key.txt
              chmod 600 ~/.age/key.txt
            end
            set -l host (hostname)
            set -l new_key (cut -d' ' -f1-2 /etc/ssh/ssh_host_ed25519_key.pub)
            cd ~/nixconf
            git remote set-url origin git@github.com:greyxp1/nixconf.git
            sed -i "s|hostPubkey = \"[^\"]*\"|hostPubkey = \"$new_key\"|" modules/system/hosts/$host/configuration.nix
            nix run .#vaultix.app.x86_64-linux.renc
            git add modules/system/hosts/$host/configuration.nix secrets/cache/
            git commit -m "chore: enroll $host"
            nh os switch
            git -c core.sshCommand="ssh -o StrictHostKeyChecking=accept-new" push
          '';
        };

        interactiveShellInit = ''
          set -g fish_greeting
          set -gx fifc_editor helix
          function _nl --on-event fish_postexec; echo; end
          function _nl_enter
            string length -q -- (commandline); or echo
            commandline -f execute
          end
        '';

        plugins =
          map (pkg: {
            name = pkg.pname;
            src = pkg.src;
          }) (with pkgs.fishPlugins; [
            fzf-fish
            autopair
            done
            fifc
          ]);
      };
    };
  };
}
