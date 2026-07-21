_: {
  home-manager.users.grey = {config, lib, ...}: let
    src = ./config;
    dst = "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/FPSAimTrainer/FPSAimTrainer";
  in {
    home.activation.kovaaks = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -d "${dst}" ]; then
        $DRY_RUN_CMD rm -rf \
          "${dst}/crosshairs" \
          "${dst}/Saved/SaveGames/Themes" \
          "${dst}/.nixconf-stamp"
        $DRY_RUN_CMD install -dm755 \
          "${dst}/crosshairs" \
          "${dst}/Saved/SaveGames/Themes"
        $DRY_RUN_CMD install -m644 -t "${dst}" \
          "${src}/PrimaryUserSettings.json" \
          "${src}/weaponsettings.ini"
        $DRY_RUN_CMD install -m644 -t "${dst}/crosshairs" "${src}/crosshairs/"*
        $DRY_RUN_CMD install -m644 -t "${dst}/Saved/SaveGames/Themes" "${src}/Themes/"*
      fi
    '';
  };
}
