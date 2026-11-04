{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  recorder = config.programs.gpu-screen-recorder.package;
  saved = pkgs.writeShellScript "recording-saved" ''
    exec ${pkgs.libnotify}/bin/notify-send "Video saved" "$1"
  '';
in {
  imports = [../../../_custom-modules/gpu-screen-recorder.nix];

  programs.gpu-screen-recorder.package = pkgs.gpu-screen-recorder.overrideAttrs {
    version = "6.1.7";
    src = inputs.gpu-screen-recorder;
  };
  programs.gpu-screen-recorder.replay = {
    enable = true;
    settings = {
      CODEC = "hevc";
      QUALITY = "very_high";
      BITRATE_MODE = "qp";
      AUDIO_DEVICE = "default_output|default_input";
      REPLAYDURATION = "120";
      OUTPUTDIR = "%h/Videos";
      # The dynamic portal stream can initially negotiate a smaller size.
      OUTPUT_RESOLUTION = "2560x1440";
      ADDITIONAL_ARGS = "-fm vfr -pixfmt yuv444 -ffmpeg-video-opts qp=10 -ro %h/Videos -ipc %t/gpu-screen-recorder.sock -sc ${saved}";
    };
  };

  programs.niri.settings.binds = lib.mapAttrs (_: command:
    lib.mkForce {
      repeat = false;
      action.spawn-sh = ''${lib.getExe' recorder "gsr-cli"} -ipc "$XDG_RUNTIME_DIR/gpu-screen-recorder.sock" ${command}'';
    }) {
    "Mod+Print" = "save-replay";
    "Mod+Shift+Print" = "toggle-replay-recording";
  };
}
