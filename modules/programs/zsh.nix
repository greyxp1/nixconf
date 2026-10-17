{
  flake.nixosModules.zsh = {
    lib,
    pkgs,
    ...
  }: {
    imports = [./_nixos-modules/zsh.nix];
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;
      histFile = "$HOME/.config/zsh/.zsh_history";
      histSize = 10000;
      setOptions = ["EXTENDED_HISTORY" "HIST_IGNORE_ALL_DUPS" "HIST_SAVE_NO_DUPS" "HIST_FCNTL_LOCK"];
      shellAliases = {
        rebuild = "alma-rebuild";
        update = "cd /home/grey/Projects/nixconf && GH_TOKEN=\"$(gh auth token --hostname github.com)\" tack update && alma-rebuild";
        clean = "nix store gc";
        ls = "eza -l --icons --git --group-directories-first --time-style=relative --no-user --no-permissions --no-filesize";
        ll = "eza --total-size";
        la = "eza -a --no-filesize";
        lla = "eza -a --total-size";
        lt = "eza --tree --no-time --no-filesize";
        llt = "eza --tree --total-size";
      };
      siteFunctions."restore-ssh-key" = ''
        mkdir -p "$HOME/.ssh" || return
        chmod 700 "$HOME/.ssh" || return
        print "Paste your SSH private key, then press Ctrl+D:"
        cat > "$HOME/.ssh/id_ed25519" || return
        chmod 600 "$HOME/.ssh/id_ed25519" || return
        ssh-add "$HOME/.ssh/id_ed25519" >/dev/null 2>&1 || true
        print "SSH private key restored"
      '';
      interactiveShellInit = ''
          mkdir -p "$HOME/.config/zsh"
          bindkey -e
          source ${pkgs.fzf}/share/fzf/completion.zsh
          source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          eval "$(${lib.getExe pkgs.zoxide} init zsh --cmd cd)"
          function y() {
            local tmp cwd
            tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
            yazi "$@" --cwd-file="$tmp"
            cwd="$(cat -- "$tmp")"
            rm -f -- "$tmp"
            if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then builtin cd -- "$cwd"; fi
          }

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
        bindkey '^[[1;5D' backward-word
        bindkey '^[[1;5C' forward-word
        bindkey -M menuselect '^J' down-line-or-history
        bindkey -M menuselect '^K' up-line-or-history
      '';
    };
  };
}
