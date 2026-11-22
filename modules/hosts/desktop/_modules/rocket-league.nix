{
  config,
  lib,
  pkgs,
  ...
}: let
  openUrl = pkgs.writeShellScript "rocket-league-open-url" ''
    unset BROWSER
    ${lib.getExe' pkgs.xdg-utils "xdg-open"} "$1" </dev/null >/dev/null 2>&1 &
  '';
  rocketLeague = pkgs.writeShellApplication {
    name = "rocket-league";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.legendary-gl pkgs.util-linux];
    text = ''
      umask 077
      exec 9>"''${XDG_RUNTIME_DIR:?}/rocket-league.lock"
      flock -n 9 || { echo "Rocket League is already starting." >&2; exit 1; }

      export GAMEID=umu-252950 STORE=egs PROTONPATH=${pkgs.proton-ge-bin.steamcompattool} PROTON_ENABLE_WAYLAND=1
      logFile="''${XDG_STATE_HOME:-$HOME/.local/state}/rocket-league/launch.log"
      mkdir -p "''${logFile%/*}"

      launch() {
        (trap "" HUP; exec legendary launch Sugar --no-wine --wrapper "setsid ${lib.getExe' pkgs.umu-launcher "umu-run"}" </dev/null >"$logFile" 2>&1)
      }
      on_exit() {
        local rc=$?
        [ "$rc" -eq 0 ] || { printf '\nPress Enter to close...'; read -r _ || :; }
        exit "$rc"
      }

      if [ "''${1:-}" != "--setup" ] \
        && ! { legendary list-installed --json 2>/dev/null | jq -e 'any(.[]; .app_name == "Sugar" and .needs_verification)' >/dev/null; } \
        && launch; then
        exit 0
      fi

      if [ ! -t 0 ] || [ ! -t 1 ]; then
        exec 9>&-
        exec ${lib.getExe' config.programs.monstar.finalPackage "monstar"} --title "Rocket League" -e "$0" --setup
      fi

      if [ "''${1:-}" = "--setup" ]; then trap on_exit EXIT; fi
      echo "If prompted to sign in, you can copy the entire JSON page (Ctrl+A, Ctrl+C) and paste it below."
      BROWSER=${openUrl} legendary auth
      legendary --yes install Sugar --skip-sdl --skip-dlcs

      printf 'Starting Rocket League. Launch log: %s\n' "$logFile"
      launch || { cat "$logFile" >&2; exit 1; }
    '';
  };
in {
  environment.systemPackages = [
    pkgs.legendary-gl
    rocketLeague
    (pkgs.makeDesktopItem {
      name = "rocket-league";
      desktopName = "Rocket League";
      icon = toString (pkgs.fetchurl {
        name = "rocket-league.png";
        url = "https://user-images.githubusercontent.com/36706276/203341314-eaaa0659-9b79-4f40-8b4a-9bc1f2b17e45.png";
        hash = "sha256-a3rynUBLOQfF5gq1mjmJRC4NWXwcuduOl7Rqvkf2Kik=";
      });
      exec = lib.getExe rocketLeague;
      categories = ["Game" "SportsGame"];
    })
  ];
}
