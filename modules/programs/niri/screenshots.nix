{inputs, ...}: {
  flake.homeModules.niri-screenshots = {config, pkgs, ...}: let
    perch = config.programs.perch.package;
    swash = inputs.swash.packages.${pkgs.stdenv.hostPlatform.system}.default;
    tesseract = pkgs.tesseract.override {enableLanguages = ["eng"];};
    niri = "${pkgs.niri}/bin/niri";
    wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
    bind = spawn-sh: {_props.repeat = false; inherit spawn-sh;};

    capture = pkgs.writeScriptBin "niri-capture-region" ''
      #!${pkgs.dash}/bin/dash
      set -eu

      OUTPUT=''${1-}
      TMP_DIR=$(${pkgs.coreutils}/bin/mktemp -d)
      PIPE="$TMP_DIR/events"
      SCREENSHOT="$TMP_DIR/capture.png"
      STREAM_PID=

      cleanup() {
        [ -z "$STREAM_PID" ] || kill "$STREAM_PID" 2>/dev/null || true
        ${pkgs.coreutils}/bin/rm -f -- "$PIPE" "$SCREENSHOT"
        ${pkgs.coreutils}/bin/rmdir -- "$TMP_DIR" 2>/dev/null || true
      }
      trap cleanup EXIT

      ${pkgs.coreutils}/bin/mkfifo "$PIPE"
      ${niri} msg --json event-stream >"$PIPE" &
      STREAM_PID=$!
      exec 3<"$PIPE"
      IFS= read -r _ <&3
      ${niri} msg action screenshot --path "$SCREENSHOT"
      ${pkgs.coreutils}/bin/timeout 60 ${pkgs.jq}/bin/jq -en --arg path "$SCREENSHOT" \
        'first(inputs | select(.ScreenshotCaptured.path? == $path))' \
        <&3 >/dev/null 2>&1
      exec 3<&-
      kill "$STREAM_PID" 2>/dev/null || true
      wait "$STREAM_PID" 2>/dev/null || true
      STREAM_PID=

      if [ -z "$OUTPUT" ]; then
        ${pkgs.coreutils}/bin/cat -- "$SCREENSHOT"
      else
        ${pkgs.coreutils}/bin/mv -- "$SCREENSHOT" "$OUTPUT"
      fi
    '';

    edit = ''
      OUTPUT_DIR="$HOME/Pictures/Screenshots"
      OUTPUT="$OUTPUT_DIR/$(${pkgs.coreutils}/bin/date +'%y-%m-%d-%H-%M-%S').png"
      ${pkgs.coreutils}/bin/mkdir -p -- "$OUTPUT_DIR"
      ${capture}/bin/niri-capture-region "$OUTPUT" && exec ${swash}/bin/swash "$OUTPUT"
    '';
  in {
    imports = [inputs.perch.homeModules.default];
    programs.perch.enable = true;
    home.packages = [swash capture pkgs.wl-clipboard];

    wayland.windowManager.niri.settings = {
      _children = [
        {
          window-rule = {
            match._props."app-id" = "^perch$";
            open-floating = true;
            focus-ring.off = {};
            border = {
              on = {};
              active-color = "#cba6f7";
              inactive-color = "#cba6f7";
            };
          };
        }
        {
          window-rule = {
            match._props."app-id" = "^dev\\.lemmy\\.swash$";
            open-floating = true;
          };
        }
      ];
      binds = {
        "Mod+Shift+C" = bind "${niri} msg pick-color | ${wlCopy} --type text/plain";
        "Shift+Print" = bind "${capture}/bin/niri-capture-region | ${perch}/bin/perch --stdin";
        "Alt+Print" = bind edit;
        "Ctrl+Print" = bind ''
          ${capture}/bin/niri-capture-region \
            | ${tesseract}/bin/tesseract stdin stdout 2>/dev/null \
            | ${wlCopy} --type text/plain
        '';
      };
    };
  };
}
