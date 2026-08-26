{
  flakeLocation,
  gid,
  homeDirectory,
  homeModules,
  inputs,
  primaryGroup,
  uid,
  username,
}: {
  lib,
  pkgs,
  ...
}: let
  systemManager = inputs.system-manager.packages.${pkgs.stdenv.hostPlatform.system}.default;
  almaDataScripts = pkgs.runCommand "alma-data-scripts" {} ''
    mkdir -p "$out/bin"
    install -m 0755 ${../../../../../scripts/alma-backup} "$out/bin/alma-backup"
    install -m 0755 ${../../../../../scripts/alma-restore} "$out/bin/alma-restore"
  '';
  alma-rebuild = pkgs.writeShellScriptBin "alma-rebuild" ''
    set -euo pipefail
    export PATH=/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

    cd ${lib.escapeShellArg flakeLocation}
    unset NIX_PATH
    system_config=$(
      NIXCONF_REPO=${lib.escapeShellArg flakeLocation} \
      NIXCONF_USERNAME=${lib.escapeShellArg username} \
      NIXCONF_UID=${lib.escapeShellArg (toString uid)} \
      NIXCONF_GID=${lib.escapeShellArg (toString gid)} \
      NIXCONF_PRIMARY_GROUP=${lib.escapeShellArg primaryGroup} \
      NIXCONF_HOME=${lib.escapeShellArg homeDirectory} \
      nix build --impure --no-link --print-out-paths \
        --file ${lib.escapeShellArg "${flakeLocation}/modules/system/hosts/alma/_build.nix"}
    )
    ${systemManager}/bin/system-manager register --store-path "$system_config" --sudo
    ${systemManager}/bin/system-manager activate --store-path "$system_config" --sudo
    [[ ! -L result ]] || /usr/bin/rm -f result
    sudo /usr/bin/systemctl restart alma-host.service
    sudo /usr/bin/systemctl restart home-manager-${username}.service
  '';
in {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    overwriteBackup = true;
    extraSpecialArgs.nixconfSystem = "systemConfigs.alma";
    sharedModules = [
      inputs.helium.homeModules.helium
      ./bottom.nix
      ./noctalia.nix
      ./portals.nix
      (import ./shell.nix {
        inherit flakeLocation homeDirectory username;
      })
      ./t3code.nix
      (
        {...}: {
          imports = homeModules;

          fonts.fontconfig.enable = true;
          flake.location = flakeLocation;
          home = {
            inherit homeDirectory username;
            packages = [
              almaDataScripts
              alma-rebuild
              inputs.ncr.packages.${pkgs.stdenv.hostPlatform.system}.default
              pkgs.nh
              pkgs.tack
            ];
            stateVersion = "26.05";
          };
          manual.manpages.enable = false;
          programs = {
            home-manager.enable = true;
            kitty.settings.symbol_map =
              "U+e000-U+e00a,U+e0a0-U+e0a2,U+e0a3,U+e0b0-U+e0b3,"
              + "U+e0b4-U+e0c8,U+e0ca,U+e0cc-U+e0d7,U+e200-U+e2a9,"
              + "U+e300-U+e3e3,U+e5fa-U+e6b7,U+e700-U+e8ef,U+ea60-U+ec1e,"
              + "U+ed00-U+efce,U+f000-U+f2ff,U+f300-U+f381,U+f400-U+f533,"
              + "U+f0001-U+f1af0 Symbols Nerd Font Mono";
          };
          targets.genericLinux.enable = true;
        }
      )
    ];
    users.${username} = {};
  };
}
