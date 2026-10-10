{inputs, ...}: {
  flake.nixosModules.nushell = {config, ...}: {
    imports = [inputs.inshellah.nixosModules.default inputs.self.wrappers.nushell.install];
    programs.inshellah.enable = true;
    wrappers.nushell.enable = true;
    environment.shells = [config.wrappers.nushell.wrapper];
    users.users.grey.shell = config.wrappers.nushell.wrapper;
  };

  flake.wrappers.nushell = {pkgs, ...}: let
    starship = inputs.self.wrappers.starship.wrap {inherit pkgs;};
    nix-index = inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-db;
  in {
    imports = ["${inputs.wrapper-nushell}/wrapperModules/n/nushell/module.nix"];
    env.STARSHIP_CONFIG = "${starship}/starship.toml";
    settings.show_banner = false;
    settings.keybindings = [
      {
        name = "accept_suggestion_or_complete";
        modifier = "none";
        keycode = "tab";
        mode = "emacs";
        event.until = [
          {send = "historyhintcomplete";}
          {
            send = "menu";
            name = "completion_menu";
          }
        ];
      }
      {
        name = "clear_scrollback";
        modifier = "control";
        keycode = "char_l";
        mode = "emacs";
        event = {
          send = "executehostcommand";
          cmd = "clear";
        };
      }
      {
        name = "completion_down";
        modifier = "control";
        keycode = "char_j";
        mode = "emacs";
        event.until = [
          {
            send = "menu";
            name = "completion_menu";
          }
          {send = "menunext";}
        ];
      }
      {
        name = "completion_up";
        modifier = "control";
        keycode = "char_k";
        mode = "emacs";
        event.send = "menuprevious";
      }
    ];

    integrations = {
      starship = {
        enable = true;
        package = starship;
      };
      zoxide = {
        enable = true;
        options = ["--cmd" "cd"];
      };
    };
    shellAliases = {
      rebuild = "nh os switch";
      update = "do { cd /home/grey/Projects/nixconf; ^tack update; ^nh os switch }";
      clean = "do { ^nh clean all --optimise --keep 1 }";
    };
    extraConfig = ''
      $env.config.hooks.command_not_found = (source ${nix-index}/etc/profile.d/command-not-found.nu)
      source ${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.nushell}/catppuccin_mocha.nu

      if ("XDG_RUNTIME_DIR" in $env) and (("SSH_AUTH_SOCK" not-in $env) or ($env.SSH_AUTH_SOCK | is-empty)) {
        $env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/ssh-agent"
      }

      def --env lg [...args] {
        $env.LAZYGIT_NEW_DIR_FILE = "~/.lazygit/newdir" | path expand
        lazygit ...$args
        if ($env.LAZYGIT_NEW_DIR_FILE | path exists) {
          cd (open $env.LAZYGIT_NEW_DIR_FILE)
          rm -f $env.LAZYGIT_NEW_DIR_FILE
        }
      }

      $env.__skip_prompt_spacing = true
      $env.config.hooks.display_output = { table --icons --index false}

      def --env clear [] {
        ^clear
        print -n "\u{1b}[3J"
        $env.__skip_prompt_spacing = true
      }

      def restore-ssh-key [] {
        mkdir ~/.ssh
        chmod 700 ~/.ssh
        print "Paste your SSH private key, then press Ctrl+D:"
        ^cat o> ~/.ssh/id_ed25519
        chmod 600 ~/.ssh/id_ed25519
        do { ^ssh-add ~/.ssh/id_ed25519 e> /dev/null } | complete | ignore
        print "SSH private key restored"
      }

      $env.config.hooks.pre_prompt = (
        $env.config.hooks.pre_prompt
        | append {||
            if ($env.__skip_prompt_spacing? | default false) {
              hide-env __skip_prompt_spacing
            } else {
              print ""
            }
          }
      )
    '';
  };
}
