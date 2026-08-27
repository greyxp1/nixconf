{
  config,
  lib,
  pkgs,
  ...
}: let
  preferencesDirectory = "${config.xdg.configHome}/net.imput.helium/Default";
  declaredPreferences = builtins.toJSON config.programs.helium.preferences;
  declaredPreferencesFile = pkgs.writeText "helium-preferences.json" declaredPreferences;
in {
  # Helium's upstream module rewrites the live Preferences database on every
  # activation. Keep declarative preferences, but leave the file untouched
  # unless one of those declared values actually differs.
  home.activation.heliumPreferences = lib.mkForce (lib.hm.dag.entryAfter ["writeBoundary"] ''
    preferences_directory=${lib.escapeShellArg preferencesDirectory}
    preferences_file="$preferences_directory/Preferences"
    declared_preferences=${lib.escapeShellArg declaredPreferences}

    $DRY_RUN_CMD mkdir -p "$preferences_directory"
    if [[ -f $preferences_file ]]; then
      if ! ${pkgs.jq}/bin/jq -e --argjson declared "$declared_preferences" \
        '(. * $declared) == .' "$preferences_file" >/dev/null; then
        if [[ -n ''${DRY_RUN_CMD:-} ]]; then
          echo "Would update declared Helium preferences in $preferences_file"
        elif ${pkgs.procps}/bin/pgrep -x helium >/dev/null; then
          echo "Refusing to change Helium preferences while Helium is running." >&2
          exit 1
        else
          temporary_file=$(${pkgs.coreutils}/bin/mktemp "$preferences_directory/.Preferences.XXXXXX")
          ${pkgs.jq}/bin/jq --argjson declared "$declared_preferences" \
            '. * $declared' "$preferences_file" > "$temporary_file"
          ${pkgs.coreutils}/bin/chmod --reference="$preferences_file" "$temporary_file"
          ${pkgs.coreutils}/bin/mv "$temporary_file" "$preferences_file"
        fi
      fi
    else
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0600 \
        ${declaredPreferencesFile} "$preferences_file"
    fi
  '');
}
