{inputs, ...}: {
  flake.homeModules.mpv = {pkgs, ...}: let
    smartcut = pkgs.python3Packages.buildPythonApplication {
      pname = "smartcut";
      version = "1.7";
      pyproject = true;
      src = inputs.smartcut;
      build-system = with pkgs.python3Packages; [setuptools wheel];
      dependencies = with pkgs.python3Packages; [av numpy tqdm];
      pythonRelaxDeps = ["av"];
      pythonImportsCheck = ["smartcut"];
    };
  in {
    catppuccin.mpv.enable = false;
    home.packages = [smartcut];
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
        hwdec = "auto-copy-safe";
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
      layout=seekbar
      window_controls=no
      vidscale=no
      scalewindowed=1.0
      scalefullscreen=1.0
      sub_margins=no
      showonpause=no
      osc_fade_strength=0
      window_fade_strength=0
    '';

    xdg.configFile."mpv/scripts/smartcut-controls.lua".text = ''
      local utils = require "mp.utils"
      local mark
      local progress = mp.create_osd_overlay("ass-events")

      local function notify(message, duration)
        mp.msg.info(message)
        mp.osd_message(message, duration or 3)
      end

      local function stamp(seconds)
        local ms = math.floor(seconds * 1000)
        return string.format("%02d-%02d-%02d-%03d",
          math.floor(ms / 3600000), math.floor(ms / 60000) % 60,
          math.floor(ms / 1000) % 60, ms % 1000)
      end

      local function select_cut_point()
        local time = mp.get_property_number("time-pos")
        if not time then
          notify("Cut failed: no video timestamp", 5)
          return
        end

        if not mark then
          mark = time
          notify("Cut start set")
          return
        end

        local start = mark
        mark = nil
        if time <= start then
          notify("Cut cancelled: end must be after start", 5)
          return
        end

        local input = mp.get_property("path")
        if not input or mp.get_property_bool("demuxer-via-network") then
          notify("Cut failed: input is not a local file", 5)
          return
        end

        local directory = utils.split_path(input)
        local filename = mp.get_property("filename")
        local stem = mp.get_property("filename/no-ext")
        local extension = filename:match("(%.[^.]*)$") or ".mp4"
        local output = utils.join_path(directory,
          "CUT_" .. stem .. "_FROM_" .. stamp(start)
            .. "_TO_" .. stamp(time) .. extension)
        progress.data = "{\\an8}Processing…"
        progress:update()

        mp.command_native_async({
          name = "subprocess",
          args = {
            "${smartcut}/bin/smartcut",
            input,
            output,
            "--keep",
            start .. "," .. time,
          },
          playback_only = false,
          capture_stderr = true,
        }, function(success, result, error)
          progress.data = ""
          progress:update()
          if success and result and result.status == 0 then
            notify("Cut complete: " .. output, 5)
            return
          end

          local detail = error or result and
            (result.stderr ~= "" and result.stderr or result.error_string)
          detail = detail and tostring(detail):gsub("%s+$", "") or "unknown error"
          mp.msg.error("Cut failed: " .. detail)
          notify("Cut failed: " .. detail, 8)
        end)
      end

      local function cancel_cut()
        if mark then
          mark = nil
          notify("Cut cancelled", 2)
        end
      end

      mp.add_forced_key_binding("c", "smartcut-select", select_cut_point)
      mp.add_forced_key_binding("C", "smartcut-cancel", cancel_cut)
      mp.register_event("file-loaded", function() mark = nil end)
    '';

    xdg.configFile."mpv/scripts/short-loop.lua".text = ''
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
}
