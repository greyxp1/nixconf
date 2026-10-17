{
  lib,
  nixos,
  pkgs,
  ...
}: {
  environment.systemPackages = [nixos.programs.zsh.package pkgs.eza pkgs.fzf];
  environment.etc =
    (lib.genAttrs ["zshrc" "zprofile" "zinputrc" "zlogin"] (name: {
      source = nixos.environment.etc.${name}.source;
      replaceExisting = true;
    }))
    // {
      zshenv = {
        replaceExisting = true;
        text = ''
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

          for p in /run/system-manager/sw /nix/var/nix/profiles/default; do
            fpath=($p/share/zsh/site-functions $p/share/zsh/$ZSH_VERSION/functions $p/share/zsh/vendor-completions $fpath)
          done
        '';
      };
    };
  environment.pathsToLink = ["/share/zsh"];
  environment.variables = {
    NCR_FLAKE = "/home/grey/Projects/nixconf";
    NH_FLAKE = "/home/grey/Projects/nixconf";
    NIX_PROFILES = "/nix/var/nix/profiles/default";
    NIX_SSL_CERT_FILE = "/etc/pki/tls/certs/ca-bundle.crt";
  };
}
