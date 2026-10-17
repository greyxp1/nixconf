{
  inputs,
  pkgs,
  ...
}: let
  src = inputs.kovaaks-config;
  dst = "/home/grey/.local/share/Steam/steamapps/common/FPSAimTrainer/FPSAimTrainer";
  save = "${dst}/Saved/SaveGames";
  configure = pkgs.writeShellScript "configure-kovaaks" ''
    set -e
    if [ -d "${dst}" ]; then
      ${pkgs.coreutils}/bin/rm -rf "${dst}/crosshairs" "${save}/Themes"
      ${pkgs.coreutils}/bin/install -dm755 "${dst}/crosshairs" "${save}/Themes"
      ${pkgs.coreutils}/bin/install -m644 -t "${save}" \
        "${src}/settings/PrimaryUserSettings.json" \
        "${src}/settings/weaponsettings.ini" \
        "${src}/settings/UI.json"
      ${pkgs.coreutils}/bin/install -Dm644 \
        "${src}/sounds/rxSound22.ogg" "${dst}/sounds/rxSound22.ogg"
      ${pkgs.coreutils}/bin/install -m644 -t "${dst}/crosshairs" "${src}/crosshairs/"*
      ${pkgs.coreutils}/bin/install -m644 -t "${save}/Themes" "${src}/Themes/"*
    fi
  '';
in {
  system.activationScripts.kovaaks = {
    deps = ["users"];
    text = "${pkgs.util-linux}/bin/runuser -u grey -- ${configure}";
  };
}
