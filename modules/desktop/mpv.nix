{
  inputs,
  pkgs,
  ...
}: {
  imports = [../_custom-modules/mpv.nix];
  programs.mpv.enable = true;
  environment.systemPackages = [inputs.mpv-smartcut.packages.${pkgs.stdenv.hostPlatform.system}.default];
  programs.mpv.settings = {
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
    screenshot-template = ''"%F-%P"'';
    sub-scale = "0.8";
    watch-later-options-remove = "sid";
    ytdl-format = "bestvideo+bestaudio";
  };
  programs.mpv.scripts = [
    pkgs.mpvScripts.modernz
    pkgs.mpvScripts.thumbfast
    pkgs.mpvScripts.mpris
    pkgs.mpvScripts.visualizer
    inputs.mpv-auto-sub-sync.packages.${pkgs.stdenv.hostPlatform.system}.default
    (pkgs.runCommand "mpv-smartcut-script" {passthru.scriptName = "mpv-smartcut.lua";} ''
      mkdir -p $out/share/mpv/scripts
      ln -s ${inputs.mpv-smartcut.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/mpv/scripts/mpv-smartcut.lua $out/share/mpv/scripts/
    '')
    ((pkgs.writeTextDir "share/mpv/scripts/short-loop.lua" ''
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
    '').overrideAttrs (_: {passthru.scriptName = "short-loop.lua";}))
  ];

  programs.mpv.scriptOpts.modernz = {
    window_controls = "no";
    vidscale = "no";
    sub_margins = "no";
  };
}
