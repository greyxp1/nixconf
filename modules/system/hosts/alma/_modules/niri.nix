{
  lib,
  pkgs,
  ...
}: let
  swapOutputs = pkgs.writeShellApplication {
    name = "niri-swap-outputs";
    runtimeInputs = [pkgs.jq];
    text = ''
      outputs=$(niri msg --json outputs)
      mapfile -t active_outputs < <(
        jq -r '
          [to_entries[] | select(.value.logical != null)]
          | sort_by(.value.logical.x)
          | .[]
          | [
              .value.name,
              .value.logical.x,
              .value.logical.y,
              .value.logical.width
            ]
          | @tsv
        ' <<< "$outputs"
      )

      if (( ''${#active_outputs[@]} != 2 )); then
        echo "Expected exactly two active outputs." >&2
        exit 1
      fi

      IFS=$'\t' read -r left_output left_x left_y left_width <<< "''${active_outputs[0]}"
      IFS=$'\t' read -r right_output right_x right_y right_width <<< "''${active_outputs[1]}"
      output_gap=$((right_x - left_x - left_width))
      temporary_x=$((right_x + right_width))

      niri msg output "$left_output" position set "$temporary_x" "$left_y"
      niri msg output "$right_output" position set "$left_x" "$left_y"
      niri msg output "$left_output" position set "$((left_x + right_width + output_gap))" "$right_y"
    '';
  };
in {
  home.packages = [swapOutputs];

  wayland.windowManager.niri.settings.binds = {
    "Mod+E" = lib.mkForce {
      _props.repeat = false;
      spawn._args = ["kitty" "yazi"];
    };
    "Mod+Shift+O" = {
      _props.repeat = false;
      spawn = "niri-swap-outputs";
    };
  };
}
