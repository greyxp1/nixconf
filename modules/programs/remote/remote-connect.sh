monitor=$(niri msg --json focused-output)
read -r width height fps < <(
  jq -er '
    .modes[.current_mode]
    | [.width, .height, (.refresh_rate / 1000 | round)] | @tsv
  ' <<< "$monitor"
)

echo "Requesting ${width}x${height} at ${fps} FPS."
export SDL_VIDEODRIVER=wayland
exec moonlight stream "${1:?Expected host}" -app Desktop -quitappafter -platform sdl \
  -width "$width" -height "$height" -fps "$fps" \
  -bitrate "${2:?Expected bitrate}" -packetsize 1024 -codec h264 \
  -keydir "${3:?Expected key directory}"
