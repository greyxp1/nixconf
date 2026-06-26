_: {
  flake.nixosModules.fish = {pkgs, ...}: {
    programs.fish.enable = true;
    users.users.grey.shell = pkgs.fish;
    home-manager.users.grey = _: {
      programs.fish = {
        enable = true;
        shellAliases = {
        };

        shellAbbrs = {
          rebuild = "nh os switch";
          update = "cd ~/nixconf && tack update && nh os switch";
          home = "sudo systemctl restart home-manager-grey.service";
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

        plugins = map (pkg: {
          name = pkg.pname;
          inherit (pkg) src;
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
