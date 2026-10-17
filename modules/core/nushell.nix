{
  inputs,
  pkgs,
  ...
}: let
  nix-index = inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-db;
  integrations = pkgs.runCommand "nushell-integrations" {} ''
    mkdir -p "$out"
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
        source ${integrations}/zoxide.nu
        const prompt_style = {
            start: $"(ansi reset)(ansi {fg: '#f2f2f2'})"
            nix: (ansi {fg: '#a6e3a1'})
            identity: $"(ansi reset)(ansi {fg: '#f2f2f2'})"
            root: (ansi {fg: '#eb4d28'})
            directory: (ansi {fg: '#f2f2f2'})
            branch: (ansi {fg: '#769ff0'})
            duration: (ansi {fg: '#999999'})
            success: $"(ansi {fg: '#769ff0' attr: b})❯(ansi reset) "
            error: $"(ansi {fg: '#eb4d28' attr: b})❯(ansi reset) "
        }

        let prompt_hostname = (sys host | get hostname | prompt-clean $in)

        def prompt-repository [directory: string] {
            if ($env.GIT_DIR? | is-not-empty) {
                return {head: ($env.GIT_DIR | path join HEAD), root: $directory}
            }
            mut directory = $directory
            loop {
                let git = ($directory | path join .git)
                let kind = ($git | path type | default "")
                let kind = if $kind == symlink { $git | path expand | path type | default "" } else { $kind }
                if $kind == dir {
                    return {head: ($git | path join HEAD), root: $directory}
                }
                if $kind == file {
                    let target = (try { open --raw $git | str trim | str replace 'gitdir: ' "" } catch { "" })
                    if $target != "" {
                        let gitdir = if ($target | str starts-with '/') {
                            $target
                        } else {
                            $directory | path join $target
                        }
                        return {head: ($gitdir | path join HEAD), root: $directory}
                    }
                }
                let parent = ($directory | path dirname)
                if $parent == $directory { return null }
                $directory = $parent
            }
        }

        def prompt-clean [text: string] {
            $text | str replace --all --regex '[\x00-\x1f\x7f-\x9f]' ""
        }

        def prompt-directory [directory: string, root: any] {
            let path = if $env.PWD == $nu.home-dir {
                '~'
            } else if ($env.PWD | str starts-with $"($nu.home-dir)/") {
                $"~/($env.PWD | path relative-to $nu.home-dir)"
            } else {
                $env.PWD
            }
            let root = if $root != null and ($env.GIT_WORK_TREE? | is-not-empty) {
                $env.GIT_WORK_TREE | path expand
            } else { $root }
            let display = if $root != null and $root != '/' and $root != $nu.home-dir {
                let relative = (try { $directory | path relative-to $root } catch { null })
                if $relative == null { $path } else if $relative == "" { $root | path basename } else { $"($root | path basename)/($relative)" }
            } else { $path }
            prompt-clean $display
        }

        def prompt-render [] {
            let directory = ($env.PWD | path expand)
            let repository = (prompt-repository $directory)
            let branch = if $repository == null { "" } else {
                let head = (try { open --raw $repository.head | str trim } catch { "" })
                if ($head | str starts-with 'ref: refs/heads/') {
                    $" ($prompt_style.branch) (prompt-clean ($head | str substring 16..))"
                } else if $head != "" {
                    $" ($prompt_style.branch) (prompt-clean ($head | str substring 0..<8))"
                } else { "" }
            }
            let directory_style = if ($env.IN_NIX_SHELL? | default "") in [pure impure] {
                $prompt_style.nix
            } else { $prompt_style.directory }
            let user = ($env.USER? | default ($nu.home-dir | path basename))
            let remote = ($env.SSH_CONNECTION? | is-not-empty) or ($env.SSH_TTY? | is-not-empty) or ($env.SSH_CLIENT? | is-not-empty)
            let identity = if $remote or $user != 'grey' {
                let style = if $user == root { $prompt_style.root } else { $prompt_style.identity }
                $"($style)(prompt-clean $user)@($prompt_hostname) "
            } else { "" }
            let milliseconds = if $env.__prompt_has_command {
                $env.CMD_DURATION_MS? | default 0 | into int
            } else { 0 }
            let duration = if $milliseconds >= 500 {
                let elapsed = if $milliseconds < 1000 {
                    $"($milliseconds)ms"
                } else if $milliseconds < 60000 {
                    $"($milliseconds / 1000 | math round --precision 1)s"
                } else if $milliseconds < 3600000 {
                    $"($milliseconds / 60000 | math round --precision 1)m"
                } else {
                    $"($milliseconds / 3600000 | math round --precision 1)h"
                }
                $" ($prompt_style.duration)($elapsed)"
            } else { "" }
            $"($prompt_style.start)($identity)($directory_style)(prompt-directory $directory $repository.root?)($branch)($duration)(ansi reset) "
        }

        $env.__prompt_has_command = false
        $env.config.hooks.pre_execution = ($env.config.hooks.pre_execution | append {|| $env.__prompt_has_command = true })
        $env.PROMPT_COMMAND = { prompt-render }
        $env.PROMPT_COMMAND_RIGHT = { "" }
        $env.PROMPT_INDICATOR = { if ($env.LAST_EXIT_CODE? | default 0) == 0 { $prompt_style.success } else { $prompt_style.error } }
        $env.PROMPT_INDICATOR_VI_INSERT = $env.PROMPT_INDICATOR
        $env.PROMPT_INDICATOR_VI_NORMAL = $env.PROMPT_INDICATOR
        $env.PROMPT_MULTILINE_INDICATOR = '::: '
        $env.config.shell_integration.osc133 = true

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

        def --wrapped "nix develop" [...args: string] {
          if ($args | any {|arg| $arg in [--command -c --help -h] or ($arg | str starts-with '--command=') }) {
            ^nix develop ...$args
          } else {
            ^nix develop ...$args --command $nu.current-exe
          }
        }

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

        $env.config.hooks.display_output = { table --icons --index false}

        def --env clear [] {
          ^clear
          print -n "\u{1b}[3J"
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
      '')
    ];
  };
}
