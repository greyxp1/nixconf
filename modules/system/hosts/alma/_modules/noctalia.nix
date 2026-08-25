{lib, ...}: {
  programs.noctalia.settings = {
    bar.default.margin_ends = lib.mkForce 415;
    plugin_settings."noctalia/screen_recorder".video_codec = lib.mkForce "h264";
  };
}
