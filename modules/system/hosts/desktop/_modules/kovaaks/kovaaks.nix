{
  home-manager.users.grey = {config, lib, ...}: let
    src = ./config;
    dst = "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/FPSAimTrainer/FPSAimTrainer";
    save = "${dst}/Saved/SaveGames";
  in {
    home.activation.kovaaks = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -d "${dst}" ]; then
        $DRY_RUN_CMD rm -rf \
          "${dst}/crosshairs" \
          "${save}/Themes"
        $DRY_RUN_CMD install -dm755 \
          "${dst}/crosshairs" \
          "${save}/Themes"
        $DRY_RUN_CMD install -m644 -t "${save}" \
          "${src}/PrimaryUserSettings.json" \
          "${src}/weaponsettings.ini" \
          "${src}/UI.json"
        $DRY_RUN_CMD install -Dm644 \
          "${src}/sounds/rxSound22.ogg" \
          "${dst}/sounds/rxSound22.ogg"
        $DRY_RUN_CMD install -m644 -t "${dst}/crosshairs" "${src}/crosshairs/"*
        $DRY_RUN_CMD install -m644 -t "${save}/Themes" "${src}/Themes/"*
      fi
    '';
  };
}
