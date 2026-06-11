_: {
  system.activationScripts.kovaaks-perms = {
    deps = ["users"];
    text = ''
      dir="/home/grey/.local/share/Steam/steamapps/common/FPSAimTrainer/FPSAimTrainer"
      if [ -d "$dir" ]; then
        chown -R grey:users "$dir"
        chmod -R u+w "$dir"
      fi
    '';
  };

  home-manager.users.grey = {lib, ...}: let
    src = ./config/.;
    dst = "$HOME/.local/share/Steam/steamapps/common/FPSAimTrainer/FPSAimTrainer";
  in {
    home.activation.kovaaks = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -d "${dst}" ]; then
        $VERBOSE_ECHO "Deploying Kovaak's config..."
        $DRY_RUN_CMD rm -rf "${dst}/crosshairs"
        $DRY_RUN_CMD cp -rT "${src}/crosshairs" "${dst}/crosshairs"
        $DRY_RUN_CMD rm -rf "${dst}/Saved/SaveGames/Themes"
        $DRY_RUN_CMD cp -rT "${src}/Themes" "${dst}/Saved/SaveGames/Themes"
        $DRY_RUN_CMD install -Dm644 "${src}/PrimaryUserSettings.json" "${dst}/PrimaryUserSettings.json"
        $DRY_RUN_CMD install -Dm644 "${src}/weaponsettings.ini" "${dst}/weaponsettings.ini"
      fi
    '';
  };
}
