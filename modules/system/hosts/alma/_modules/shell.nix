{inputs}: {pkgs, ...}: let
  zsh = inputs.self.wrappers.zsh.wrap {
    inherit pkgs;
    enableCompletion = true;
    integrations = {
      fzf.enable = true;
      zoxide = {
        enable = true;
        options = ["--cmd" "cd"];
      };
      starship = {
        enable = true;
        package = inputs.self.wrappers.starship.wrap {inherit pkgs;};
      };
      yazi.enable = true;
    };
    defaultKeymap = "emacs";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      enable = true;
      path = "$HOME/.config/zsh/.zsh_history";
      extended = true;
      ignoreAllDups = true;
      saveNoDups = true;
    };
    historySubstringSearch.enable = true;
    zshAliases = {
      rebuild = "alma-rebuild";
      update = "cd /home/grey/Projects/nixconf && tack update && alma-rebuild";
      clean = "nix store gc";
      ls = "eza -l --icons --git --group-directories-first --time-style=relative --no-user --no-permissions --no-filesize";
      ll = "eza --total-size";
      la = "eza -a --no-filesize";
      lla = "eza -a --total-size";
      lt = "eza --tree --no-time --no-filesize";
      llt = "eza --tree --total-size";
    };
    zshenv.content = ''
      [[ ! -r /etc/profile.d/system-manager-path.sh ]] || source /etc/profile.d/system-manager-path.sh
      if [[ -n $XDG_RUNTIME_DIR && -z $SSH_AUTH_SOCK ]]; then
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
      fi
      typeset -U path
      path=(
        /run/system-manager/sw/bin
        /nix/var/nix/profiles/default/bin
        /home/grey/.local/bin
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
        /run/system-manager/sw/share
        /nix/var/nix/profiles/default/share
        /usr/local/share
        /usr/share
        ''${(s.:.)XDG_DATA_DIRS}
      )
      export XDG_DATA_DIRS="''${(j.:.)xdg_data_dirs}"
      unset xdg_data_dirs
    '';
    zlogin.content = ''
      if [[ $USER == grey && $TTY == /dev/tty1 ]]; then
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
    zshrc.content = ''
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
in {
  environment.systemPackages = [zsh pkgs.eza pkgs.fzf];
  environment.variables = {
    NCR_FLAKE = "/home/grey/Projects/nixconf";
    NH_FLAKE = "/home/grey/Projects/nixconf";
    NIX_PROFILES = "/nix/var/nix/profiles/default";
    NIX_SSL_CERT_FILE = "/etc/pki/tls/certs/ca-bundle.crt";
  };
}
