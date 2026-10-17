{
  inputs,
  config,
  pkgs,
  ...
}: let
  nix-index = inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-db;
  integrations = pkgs.runCommand "nushell-integrations" {} ''
    mkdir -p "$out"
    STARSHIP_CACHE="$TMPDIR/starship" ${config.programs.starship.package}/bin/starship init nu > "$out/starship.nu"
    ${pkgs.zoxide}/bin/zoxide init nushell --cmd cd > "$out/zoxide.nu"
  '';
  settings = {
    show_banner = false;
    keybindings = [
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
  };
in {
  imports = [inputs.inshellah.nixosModules.default];
  programs.inshellah.enable = true;
  environment.shells = [pkgs.nushell];
  users.users.grey.shell = pkgs.nushell;
  programs.nushell = {
    enable = true;
    autoloads = [
      (pkgs.writeTextDir "share/nushell/vendor/autoload/10-nixconf.nu" ''
        let system_env = ^${pkgs.bash}/bin/bash --noprofile --norc -c 'source /etc/set-environment >/dev/null && ${pkgs.coreutils}/bin/env -0'
          | split row (char nul)
          | where {|entry| $entry != "" }
          | split column --number 2 '=' name value
          | where {|entry| $entry.name not-in $env and $entry.name not-in ['_' 'SHLVL' '__NIXOS_SET_ENVIRONMENT_DONE'] }
          | reduce --fold {} {|entry, vars| $vars | insert $entry.name $entry.value }
        load-env $system_env

        $env.config = ($env.config | merge deep (${builtins.toJSON (builtins.toJSON settings)} | from json))
        $env.STARSHIP_CONFIG = ${builtins.toJSON config.environment.variables.STARSHIP_CONFIG}
        source ${integrations}/zoxide.nu
        use ${integrations}/starship.nu

        def --env y [...args] {
          let tmp = (mktemp -t "yazi-cwd.XXXXX")
          ^yazi ...$args --cwd-file $tmp
          let cwd = (open $tmp)
          rm -fp $tmp
          if $cwd != "" and $cwd != $env.PWD {
            cd $cwd
          }
        }

        alias rebuild = nh os switch
        alias update = do { cd /home/grey/Projects/nixconf; with-env { GH_TOKEN: (^gh auth token --hostname github.com) } { ^tack update }; ^nh os switch }
        alias clean = do { ^nh clean all --optimise --keep 1 }

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
      '')
    ];
  };
}
