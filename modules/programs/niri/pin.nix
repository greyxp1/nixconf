_: {
  flake.homeModules.niri-pin = {pkgs, ...}: {
    home.packages = [
      pkgs.jq
      (pkgs.writeScriptBin "niri-pin-to-screen" ''
        #!${pkgs.dash}/bin/dash
        set -eu
        PIPE=$(${pkgs.coreutils}/bin/mktemp -u)
        ${pkgs.coreutils}/bin/mkfifo "$PIPE"

        cleanup() {
          rm -f "$PIPE"
          kill "$STREAM_PID" 2>/dev/null || true
          kill "$TIMER_PID" 2>/dev/null || true
        }
        trap cleanup EXIT

        ${pkgs.niri-unstable}/bin/niri msg --json event-stream > "$PIPE" &
        STREAM_PID=$!
        exec 3< "$PIPE"

        ${pkgs.niri-unstable}/bin/niri msg action screenshot

        ( ${pkgs.coreutils}/bin/sleep 15 && kill "$STREAM_PID" 2>/dev/null ) &
        TIMER_PID=$!

        SCREENSHOT=
        while IFS= read -r LINE <&3; do
          P=$(printf '%s\n' "$LINE" \
            | ${pkgs.jq}/bin/jq -r '.ScreenshotCaptured.path? // empty' 2>/dev/null \
            || true)
          [ -n "$P" ] && SCREENSHOT="$P" && break
        done

        exec 3<&-
        kill "$TIMER_PID" 2>/dev/null || true
        kill "$STREAM_PID" 2>/dev/null || true
        [ -z "$SCREENSHOT" ] && exit 0

        mpv-pin-image Niri-Pin-Surface "$SCREENSHOT"
        rm -f "$SCREENSHOT"
      '')
    ];

    wayland.windowManager.niri.settings = {
      window-rule = [
        {
          match._props.title = "^Niri-Pin-Surface$";
          open-floating = true;
          focus-ring.off = {};
        }
      ];
      binds."Shift+Print" = {
        _props.repeat = false;
        spawn = "niri-pin-to-screen";
      };
    };
  };
}
