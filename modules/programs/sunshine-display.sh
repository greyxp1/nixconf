state="${XDG_RUNTIME_DIR:?}/sunshine-display-mode"
output=DP-2
umask 077

restore() {
  if [[ -f "$state" ]]; then
    IFS=$'\t' read -r mode scale < "$state"
    niri msg output "$output" mode "$mode"
    niri msg output "$output" scale "$scale"
    rm -- "$state"
  fi
}

case "${1:?Expected start or restore}" in
  start)
    [[ "${SUNSHINE_APP_NAME:-}" == Desktop ]] || exit 0
    if [[ ! -f "$state" ]]; then
      niri msg --json outputs | jq -er --arg output "$output" '
        .[$output] | .modes[.current_mode] as $mode
        | ["\($mode.width)x\($mode.height)@\($mode.refresh_rate / 1000)", .logical.scale]
        | @tsv
      ' > "$state.tmp"
      mv -- "$state.tmp" "$state"
    fi
    trap restore ERR
    niri msg output "$output" mode 1920x1080@60.000
    niri msg output "$output" scale 1
    # Wait for the modeset before Sunshine initializes capture.
    for ((attempt = 0; attempt < 40; attempt++)); do
      if niri msg --json outputs | jq -e --arg output "$output" '
        .[$output] | .modes[.current_mode] as $mode
        | $mode.width == 1920 and $mode.height == 1080
          and $mode.refresh_rate == 60000 and .logical.scale == 1
      ' > /dev/null; then
        exit 0
      fi
      sleep 0.05
    done
    echo "Niri did not apply the streaming display mode." >&2
    restore
    exit 1
    ;;
  restore)
    restore
    ;;
  *)
    echo "Expected start or restore." >&2
    exit 1
    ;;
esac
