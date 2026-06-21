{...}: {
  flake.nixosModules.mpv = {...}: {
    home-manager.users.grey = {pkgs, ...}: {
      catppuccin.mpv.enable = false;
      programs.mpv = {
        enable = true;
        package = pkgs.mpv.override {
          scripts = with pkgs.mpvScripts; [
            modernz
            thumbfast
            encode
            mpris
            visualizer
            #evafast
          ];
        };

        bindings = {c = "script-message-to encode set-timestamp encode_clip";};

        config = {
          vo = "gpu-next";
          gpu-context = "wayland";
          hwdec = "auto-safe"; # picks up nvdec on the nvidia desktop host
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

      xdg.configFile."mpv/script-opts/encode_clip.conf".text = ''
        output_directory=
        output_format=$f_$s-$e.$x
        codec=-c:v libx264 -crf 16 -preset slow -colorspace bt709 -color_primaries bt709 -color_trc bt709 -pix_fmt yuv420p -c:a libopus -b:a 128k -sn
        print=yes
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
  };
}
