{
  config,
  lib,
  pkgs,
  ...
}: let
  audio = "default_output|default_input";
  # The dynamic portal stream can initially negotiate a smaller size.
  resolution = "2560x1440";
  saved = pkgs.writeShellScript "recording-saved" ''
    exec ${pkgs.libnotify}/bin/notify-send "Video saved" "$1"
  '';
in {
  imports = [../../../_custom-modules/gpu-screen-recorder.nix];

  programs.gpu-screen-recorder.replay = {
    enable = true;
    settings = {
      CODEC = "av1";
      QUALITY = "18000";
      AUDIO_DEVICE = audio;
      OUTPUT_RESOLUTION = resolution;
      ADDITIONAL_ARGS = "-sc ${saved}";
    };
  };

  programs.gpu-screen-recorder.recording = {
    enable = true;
    extraArgs = [
      "-s" resolution "-a" audio
      "-k" "hevc" "-bm" "qp"
      "-pixfmt" "yuv444" "-ffmpeg-video-opts" "qp=10"
    ];
    onSave = saved;
  };

  programs.niri.settings.binds = {
    "Mod+Print".action.spawn = lib.mkForce [
      "systemctl" "--user" "kill" "--kill-whom=main" "--signal=USR1" "gpu-screen-recorder.service"
    ];
    "Mod+Shift+Print".action.spawn-sh = config.programs.gpu-screen-recorder.recording.toggleCommand;
  };
}
