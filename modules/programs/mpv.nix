{inputs, ...}: {
  perSystem = {system, ...}: {
    packages.mpv-smartcut = inputs.mpv-smartcut.packages.${system}.default;
  };

  flake.homeModules.mpv = {pkgs, ...}: let
    mpv-smartcut = inputs.mpv-smartcut.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    catppuccin.mpv.enable = false;
    home.packages = [mpv-smartcut];
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
        vo = "gpu";
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

    xdg.configFile = {
      "mpv/script-opts/modernz.conf".text = ''
        layout=seekbar
        window_controls=no
        vidscale=no
        sub_margins=no
      '';

      "mpv/scripts/mpv-smartcut.lua".source =
        "${mpv-smartcut}/share/mpv/scripts/mpv-smartcut.lua";

      "mpv/scripts/short-loop.lua".text = ''
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
          local loop = duration and duration > 0 and duration <= 130 and has_real_video()
          mp.set_property("loop-file", loop and "inf" or "no")
          mp.set_property_bool("save-position-on-quit", not loop)
        end

        mp.register_event("file-loaded", maybe_loop)
      '';
    };
  };
}
