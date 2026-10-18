{
  config,
  lib,
  nixos,
  pkgs,
  ...
}: {
  environment.etc =
    {
      "set-environment".source = config.environment.etc."profile.d/system-manager-path.sh".source;
      "fish/nixos-env-preinit.fish".text = ''
        set fish_function_path ${pkgs.fishPlugins.foreign-env}/share/fish/vendor_functions.d
        if not set -q __NIXOS_SET_ENVIRONMENT_DONE
          fenv source /etc/set-environment
        end
        set -e fish_function_path
      '';
      "fish/foreign-env/shellInit".text = "";
      "fish/foreign-env/loginShellInit".text = "";
      "fish/foreign-env/interactiveShellInit".text = "";
    }
    // lib.mapAttrs (_: file: {inherit (file) source;})
    (lib.filterAttrs (name: _:
      lib.hasPrefix "fish/" name
      && !(builtins.elem name [
        "fish/nixos-env-preinit.fish"
        "fish/foreign-env/shellInit"
        "fish/foreign-env/loginShellInit"
        "fish/foreign-env/interactiveShellInit"
      ]))
    nixos.environment.etc);
  environment.extraInit = ''
    if [ -z "$SSH_AUTH_SOCK" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
      export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
    fi
    export __NIXOS_SET_ENVIRONMENT_DONE=1
  '';
  environment.pathsToLink = nixos.environment.pathsToLink;
  environment.extraSetup = nixos.environment.extraSetup;
  environment.systemPackages = [
    (pkgs.writeTextDir "share/fish/vendor_conf.d/90-alma.fish" ''
      if status is-interactive
        alias rebuild alma-rebuild
        alias clean 'nix store gc'
      end
      if status is-login; and status is-interactive; and test "$USER" = grey
        if test (${pkgs.coreutils}/bin/tty) = /dev/tty1
          niri-session -l
        end
      end
    '')
  ];
  environment.variables = {
    NCR_FLAKE = "/home/grey/Projects/nixconf";
    NH_FLAKE = "/home/grey/Projects/nixconf";
    NIX_PROFILES = "/nix/var/nix/profiles/default /run/system-manager/sw";
    NIX_SSL_CERT_FILE = "/etc/pki/tls/certs/ca-bundle.crt";
  };
}
