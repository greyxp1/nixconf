{
  flakeLocation,
  homeDirectory,
  username,
}: {
  config,
  lib,
  ...
}: {
  home.sessionVariables = {
    NCR_FLAKE = flakeLocation;
    NH_FLAKE = flakeLocation;
    NIX_PROFILES = "/nix/var/nix/profiles/default ${config.home.profileDirectory}";
    NIX_SSL_CERT_FILE = "/etc/pki/tls/certs/ca-bundle.crt";
  };

  programs = {
    eza = {
      enable = true;
      extraOptions = [
        "-l"
        "--icons"
        "--git"
        "--group-directories-first"
        "--time-style=relative"
        "--no-user"
        "--no-permissions"
      ];
    };
    nushell.enable = lib.mkForce false;
    zsh = {
      enable = true;
      defaultKeymap = "emacs";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        extended = true;
        ignoreAllDups = true;
        saveNoDups = true;
      };
      historySubstringSearch.enable = true;
      shellAliases = {
        rebuild = "alma-rebuild";
        update = "cd ${lib.escapeShellArg flakeLocation} && tack update && alma-rebuild";
        clean = "nix store gc";
        ls = "eza --no-filesize";
        ll = "eza --total-size";
        la = "eza -a --no-filesize";
        lla = "eza -a --total-size";
        lt = "eza --tree --no-time --no-filesize";
        llt = "eza --tree --total-size";
      };
      envExtra = ''
        typeset -U path
        path=(
          ${config.home.profileDirectory}/bin
          /run/system-manager/sw/bin
          /nix/var/nix/profiles/default/bin
          ${homeDirectory}/.local/bin
          /usr/local/bin
          /usr/bin
          /bin
          /usr/local/sbin
          /usr/sbin
          /sbin
          $path
        )
        export PATH

        typeset -aU xdg_data_dirs
        xdg_data_dirs=(
          ${config.home.profileDirectory}/share
          /run/system-manager/sw/share
          /nix/var/nix/profiles/default/share
          /usr/local/share
          /usr/share
          ''${(s.:.)XDG_DATA_DIRS}
        )
        export XDG_DATA_DIRS="''${(j.:.)xdg_data_dirs}"
        unset xdg_data_dirs
      '';
      loginExtra = ''
        if [[ $USER == ${lib.escapeShellArg username} && $TTY == /dev/tty1 ]]; then
          niri-session -l
        fi
      '';
      siteFunctions."restore-ssh-key" = ''
        mkdir -p "$HOME/.ssh" || return
        chmod 700 "$HOME/.ssh" || return
        print "Paste your SSH private key, then press Ctrl+D:"
        cat > "$HOME/.ssh/id_ed25519" || return
        chmod 600 "$HOME/.ssh/id_ed25519" || return
        ssh-add "$HOME/.ssh/id_ed25519" >/dev/null 2>&1 || true
        print "SSH private key restored"
      '';
      initContent = lib.mkAfter ''
        autoload -Uz add-zsh-hook
        typeset -g __nixconf_skip_prompt_spacing=true

        _nixconf_prompt_spacing() {
          if [[ ''${__nixconf_skip_prompt_spacing:-false} == true ]]; then
            unset __nixconf_skip_prompt_spacing
          else
            print
          fi
        }
        add-zsh-hook precmd _nixconf_prompt_spacing

        _nixconf_accept_suggestion_or_complete() {
          if [[ -n $POSTDISPLAY ]]; then
            zle autosuggest-accept
          else
            zle expand-or-complete
          fi
        }
        zle -N _nixconf_accept_suggestion_or_complete

        _nixconf_clear_scrollback() {
          print -n $'\e[2J\e[3J\e[H'
          typeset -g __nixconf_skip_prompt_spacing=true
          zle reset-prompt
        }
        zle -N _nixconf_clear_scrollback

        zmodload zsh/complist
        zstyle ':completion:*' menu select
        bindkey '^I' _nixconf_accept_suggestion_or_complete
        bindkey '^L' _nixconf_clear_scrollback
        bindkey '^J' menu-complete
        bindkey '^K' reverse-menu-complete
        bindkey -M menuselect '^J' down-line-or-history
        bindkey -M menuselect '^K' up-line-or-history
      '';
    };
  };
}
