state="${XDG_RUNTIME_DIR:?}/sunshine-display-mode"
umask 077

restore() {
  if [[ -f "$state" ]]; then
    IFS=$'\t' read -r output mode scale < "$state"
    niri msg output "$output" mode "$mode"
    niri msg output "$output" scale "$scale"
    rm -- "$state"
  fi
}

case "${1:?Expected start or restore}" in
  start)
    [[ "${SUNSHINE_APP_NAME:-}" == Desktop ]] || exit 0
    if [[ ! -f "$state" ]]; then
      niri msg --json outputs | jq -er '
        [.[] | select(.logical != null)]
        | sort_by(if .logical.x == 0 and .logical.y == 0 then 0 else 1 end)
        | first | .modes[.current_mode] as $mode
        | [.name, "\($mode.width)x\($mode.height)@\($mode.refresh_rate / 1000)", .logical.scale]
        | @tsv
      ' > "$state.tmp"
      mv -- "$state.tmp" "$state"
    fi
    IFS=$'\t' read -r output mode scale < "$state"
    target=$(niri msg --json outputs | jq -er --arg output "$output" \
      --argjson width "${SUNSHINE_CLIENT_WIDTH:?}" \
      --argjson height "${SUNSHINE_CLIENT_HEIGHT:?}" \
      --argjson fps "${SUNSHINE_CLIENT_FPS:?}" '
        .[$output] as $display
        | [$display.modes[] | select(.width == $width and .height == $height)] as $matching
        | (if ($matching | length) > 0 then $matching else
            [$display.modes[] | select(
              .width == $display.modes[$display.current_mode].width
              and .height == $display.modes[$display.current_mode].height)]
          end)
        | min_by((.refresh_rate / 1000 - $fps) | fabs)
        | ["\(.width)x\(.height)@\(.refresh_rate / 1000)",
           .width, .height, .refresh_rate] | @tsv
      ')
    IFS=$'\t' read -r target_mode width height refresh <<< "$target"
    echo "Client requested ${SUNSHINE_CLIENT_WIDTH}x${SUNSHINE_CLIENT_HEIGHT}@${SUNSHINE_CLIENT_FPS}. Using $output $target_mode."
    trap restore ERR
    niri msg output "$output" mode "$target_mode"
    niri msg output "$output" scale 1
    # Wait for the modeset before Sunshine initializes capture.
    for ((attempt = 0; attempt < 40; attempt++)); do
      if niri msg --json outputs | jq -e --arg output "$output" \
        --argjson width "$width" --argjson height "$height" --argjson refresh "$refresh" '
        .[$output] | .modes[.current_mode] as $mode
        | $mode.width == $width and $mode.height == $height
          and $mode.refresh_rate == $refresh and .logical.scale == 1
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
