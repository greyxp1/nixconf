{
  config,
  lib,
  nixos,
  pkgs,
  ...
}: {
  environment.etc."set-environment".source = config.environment.etc."profile.d/system-manager-path.sh".source;
  environment.pathsToLink = nixos.environment.pathsToLink;
  environment.extraSetup = nixos.environment.extraSetup;
  environment.systemPackages = [
    (lib.hiPrio (pkgs.symlinkJoin {
      name = "alma-nushell";
      paths = [nixos.programs.nushell.package];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/nu \
          --set-default XDG_DATA_DIRS /usr/local/share:/usr/share \
          --prefix XDG_DATA_DIRS : /run/system-manager/sw/share
      '';
      meta = nixos.programs.nushell.package.meta;
    }))
    (pkgs.writeTextDir "share/nushell/vendor/autoload/90-alma.nu" ''
      alias rebuild = alma-rebuild
      alias update = do { cd /home/grey/Projects/nixconf; with-env { GH_TOKEN: (^gh auth token --hostname github.com) } { ^tack update }; ^alma-rebuild }
      alias clean = nix store gc

      if $nu.is-login and $nu.is-interactive and ($env.USER? == 'grey') {
        let tty = (do { ^${pkgs.coreutils}/bin/tty } | complete | get stdout | str trim)
        if $tty == '/dev/tty1' {
          ^niri-session -l
        }
      }
    '')
  ];
  environment.variables = {
    NCR_FLAKE = "/home/grey/Projects/nixconf";
    NH_FLAKE = "/home/grey/Projects/nixconf";
    NIX_PROFILES = "/nix/var/nix/profiles/default";
    NIX_SSL_CERT_FILE = "/etc/pki/tls/certs/ca-bundle.crt";
  };
}
