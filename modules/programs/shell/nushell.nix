{...}: {
  flake.nixosModules.shell = {pkgs, ...}: {
    programs.fish.enable = true;
    users.users.grey.shell = pkgs.nushell;
    home-manager.users.grey = {...}: {
      programs.carapace.enable = true;
      programs.carapace.enableNushellIntegration = false;
      programs.nushell = {
        enable = true;
        extraEnv = ''
          $env.__NU_NL = false
        '';
        extraConfig = ''
          # ── Completions ─────────────────────────────────────────────────────
          # Taken verbatim from https://www.nushell.sh/cookbook/external_completers.html
          #
          # fish handles completions from man-page parsing, covering tools
          # carapace doesn't know about (nh, ragenix, lstr, etc).
          # The path-quoting block converts POSIX escapes fish uses into
          # double-quoted paths that nushell understands.
          let fish_completer = {|spans|
            fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
            | from tsv --flexible --noheaders --no-infer
            | rename value description
            | update value {|row|
                let value = $row.value
                let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
                if ($need_quote and ($value | path exists)) {
                  let expanded_path = if ($value starts-with ~) {$value | path expand --no-symlink} else {$value}
                  $'"($expanded_path | str replace --all "\"" "\\\"")"'
                } else {$value}
              }
          }

          # CARAPACE_LENIENT stops carapace from erroring on unknown flags
          # (returns a labelled error entry instead of a hard failure).
          let carapace_completer = {|spans: list<string>|
            CARAPACE_LENIENT=1 carapace $spans.0 nushell ...$spans | from json
          }

          # Expand any alias first (fixes the known nushell alias-completion bug),
          # then try carapace. If carapace errors or returns nothing — which it
          # will for NixOS-specific tools like nh — fall back to fish.
          let external_completer = {|spans|
            let expanded_alias = scope aliases | where name == $spans.0 | get -o 0.expansion
            let spans = if $expanded_alias != null {
              $spans | skip 1 | prepend ($expanded_alias | split row ' ' | take 1)
            } else { $spans }

            let result = try { do $carapace_completer $spans } catch { [] }
            if ($result | is-empty) { do $fish_completer $spans } else { $result }
          }

          $env.config = ($env.config | merge {
            show_banner: false
            table: { mode: "rounded" }
            completions: {
              algorithm: "fuzzy"
              external: { enable: true, completer: $external_completer }
            }
            # ── Blank line between commands ──────────────────────────────────
            hooks: {
              pre_execution: [{ code: {|| $env.__NU_NL = true } }]
              pre_prompt: [{
                code: {||
                  if ($env.__NU_NL? | default false) {
                    $env.__NU_NL = false
                    let cmd = (
                      try { history | last | get command | str trim | split row " " | first }
                      catch { "" }
                    )
                    if $cmd not-in ["clear" "ll" ""] { print "" }
                  }
                }
              }]
            }
          })

          # ── Aliases and functions ────────────────────────────────────────────
          alias ll       = eza --long --icons --git --group-directories-first --time-style=relative --header
          alias cat      = bat --paging=never
          alias rebuild  = nh os switch
          alias update   = nh os switch --update
          alias clean    = nh clean all
          alias optimise = nix store optimise -v
          alias tree     = lstr -g --icons --git-status
          alias treell   = lstr -a -s -p --icons
          alias treei    = lstr interactive -g --icons --git-status

          def clear [] {
            print -n "\e[3J"
            ^clear
          }

          def home [] {
            sudo systemctl restart home-manager-grey.service
          }

          def enroll [] {
            let key_file = ($env.HOME | path join ".age/key.txt")
            if not ($key_file | path exists) {
              print "Paste your AGE-SECRET-KEY then press Ctrl+D:"
              mkdir ($env.HOME | path join ".age")
              bash -c $"cat > '($key_file)'"
              ^chmod 600 $key_file
            }

            nh os switch

            let host    = (^hostname | str trim)
            let new_key = (
              open /etc/ssh/ssh_host_ed25519_key.pub
              | str trim | split row " " | first 2 | str join " "
            )
            let secrets = ($env.HOME | path join "nixconf/secrets/secrets.nix")

            if (open $secrets | str contains $"# ($host)") {
              ^sed -i $"s|\"ssh-ed25519 [^\"]*\" # ($host)|\"($new_key)\" # ($host)|" $secrets
            } else {
              ^awk -v $"e=    \"($new_key)\" # ($host)" '/^\s*\];/ { print e } { print }' $secrets
              | save --force /tmp/_s.nix
              cp /tmp/_s.nix $secrets
            }

            cd ~/nixconf
            ragenix --rules secrets/secrets.nix -r -i $key_file
            git add secrets/
            git commit -m $"chore: enroll ($host)"
            git push
          }
        '';
      };
    };
  };
}
