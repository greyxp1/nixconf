{
  gid,
  inputs,
  primaryGroup,
  uid,
  lib,
  pkgs,
  ...
}: let
  systemManager = inputs.system-manager.packages.${pkgs.stdenv.hostPlatform.system}.default;
  alma-rebuild = pkgs.writeShellScriptBin "alma-rebuild" ''
    set -euo pipefail
    umask 022
    export PATH=/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

    cd /home/grey/Projects/nixconf
    unset NIX_PATH
    system_config=$(
      NIXCONF_UID=${lib.escapeShellArg (toString uid)} \
      NIXCONF_GID=${lib.escapeShellArg (toString gid)} \
      NIXCONF_PRIMARY_GROUP=${lib.escapeShellArg primaryGroup} \
      nix build --impure --no-link --print-out-paths \
        --file /home/grey/Projects/nixconf/modules/system/hosts/alma/_build.nix
    )
    ${systemManager}/bin/system-manager register --store-path "$system_config" --sudo
    ${systemManager}/bin/system-manager activate --store-path "$system_config" --sudo
    [[ ! -L result ]] || /usr/bin/rm -f result
    sudo /usr/bin/systemctl restart alma-host.service
  '';
in {
  imports = [(import ./shell.nix {inherit inputs;})];
  environment.systemPackages = [
    alma-rebuild
    inputs.ncr.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.tack
  ];
}
