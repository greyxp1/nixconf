{inputs, ...}: {
  flake.homeModules.mpv = {pkgs, ...}: {
    catppuccin.mpv.enable = false;
    xdg.configFile."mpv/scripts/videoclip".source = inputs.videoclip;
    programs.mpv = {
      enable = true;
      package = pkgs.mpv.override {
        scripts = with pkgs.mpvScripts; [
          modernz
          thumbfast
          mpris
          visualizer
        ];
      };

      config = {
        vo = "gpu-next";
        gpu-context = "wayland";
        hwdec = "auto-safe";
        profile = "gpu-hq";
        cache = "yes";
        demuxer-max-bytes = "512MiB";
        demuxer-max-back-bytes = "256MiB";
        osc = "no";
        osd-bar = "no";
        border = "no";
        screenshot-format = "png";
        screenshot-directory = "~/Pictures/Screenshots";
        screenshot-template = "%F-%P";
        ytdl-format = "bestvideo+bestaudio";
      };
    };

    xdg.configFile."mpv/script-opts/modernz.conf".text = ''
      vidscale=no
      scalewindowed=1.0
      scalefullscreen=1.0
      sub_margins=no
    '';

    xdg.configFile."mpv/script-opts/videoclip.conf".text = ''
      video_quality=16
      preset=veryslow
      video_bitrate=20M
      video_width=-2
      video_height=-2
      audio_format=aac
      audio_bitrate=256k
    '';

    xdg.configFile."mpv/scripts/short-loop.lua".text = ''
      local threshold = 120 -- seconds

      local function has_real_video()
        local tracks = mp.get_property_native("track-list")
        if not tracks then return false end
        for _, track in ipairs(tracks) do
          if track.type == "video" and not track.image then
            return true
          end
        end
        return false
      end

      local function maybe_loop()
        local duration = mp.get_property_number("duration")
        local short = duration and duration > 0 and duration < threshold

        if has_real_video() and short then
          mp.set_property("loop-file", "inf")
        else
          mp.set_property("loop-file", "no")
        end

        mp.set_property_bool("save-position-on-quit", not short)
      end

      mp.register_event("file-loaded", maybe_loop)
    '';
  };
}
