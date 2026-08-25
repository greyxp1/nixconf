{
  flakeLocation,
  homeDirectory,
  username,
}: {
  config,
  lib,
  pkgs,
  ...
}: let
  zoxideNushell = pkgs.runCommand "zoxide-nushell-config.nu" {} ''
    ${lib.getExe pkgs.zoxide} init nushell --cmd z > "$out"
  '';
in {
  home.sessionVariables = {
    NCR_FLAKE = flakeLocation;
    NH_FLAKE = flakeLocation;
    NIX_PROFILES = "/nix/var/nix/profiles/default ${config.home.profileDirectory}";
    NIX_SSL_CERT_FILE = "/etc/pki/tls/certs/ca-bundle.crt";
  };

  programs = {
    nushell = {
      environmentVariables = {
        PATH = lib.hm.nushell.mkNushellInline ''
          ([
            "${config.home.profileDirectory}/bin"
            "/run/system-manager/sw/bin"
            "/nix/var/nix/profiles/default/bin"
            "${homeDirectory}/.local/bin"
            "/usr/local/bin"
            "/usr/bin"
            "/bin"
            "/usr/local/sbin"
            "/usr/sbin"
            "/sbin"
          ]
            | append ($env.PATH | split row (char esep))
            | uniq)
        '';
        XDG_DATA_DIRS = lib.mkForce (lib.hm.nushell.mkNushellInline ''
          ([
            "${config.home.profileDirectory}/share"
            "/run/system-manager/sw/share"
            "/nix/var/nix/profiles/default/share"
            "/usr/local/share"
            "/usr/share"
          ]
            | append (
                $env.XDG_DATA_DIRS?
                | default ""
                | split row (char esep)
                | where {|path| not ($path | is-empty) }
              )
            | uniq
            | str join (char esep))
        '');
      };
      extraLogin = ''
        if $env.USER == "${username}" and (^tty | str trim) == "/dev/tty1" {
          ^niri-session -l
        }
      '';
      extraConfig = lib.mkAfter ''
        source ${zoxideNushell}

        # Alma's zoxide/Nushell integration treats a trailing slash as
        # part of the search term instead of a directory separator.
        alias __zoxide_builtin_cd = cd
        def --env --wrapped cd [...rest: directory] {
          let normalized = ($rest | each {|arg|
            let text = ($arg | into string)
            if $text == "/" {
              $text
            } else {
              $text | str trim --right --char "/"
            }
          })
          let path = match $normalized {
            [] => { "~" },
            [ "-" ] => { "-" },
            [ $arg ] if ($arg | path expand | path type) == "dir" => { $arg },
            _ => {
              ^zoxide query --exclude $env.PWD -- ...$normalized
              | str trim -r -c (char newline)
            }
          }
          __zoxide_builtin_cd $path
        }
      '';
      shellAliases = lib.mkForce {
        rebuild = "alma-rebuild";
        update = "do { cd ${flakeLocation}; ^tack update; ^alma-rebuild }";
        clean = "nix store gc";
      };
    };
    zoxide.enableNushellIntegration = lib.mkForce false;
  };
}
