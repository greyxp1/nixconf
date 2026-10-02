{inputs, ...}: {
  perSystem = {system, ...}: {
    packages.mpv-smartcut = inputs.mpv-smartcut.packages.${system}.default;
  };

  flake.nixosModules.mpv = {pkgs, ...}: {
    imports = [inputs.self.wrappers.mpv.install];
    wrappers.mpv.enable = true;
    environment.systemPackages = [inputs.mpv-smartcut.packages.${pkgs.stdenv.hostPlatform.system}.default];
  };

  flake.wrappers.mpv = {
    lib,
    pkgs,
    wlib,
    ...
  }: {
    imports = [wlib.wrapperModules.mpv];
    "mpv.conf".content = lib.generators.toKeyValue {} {
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
    script = {
      modernz.path = pkgs.mpvScripts.modernz;
      thumbfast.path = pkgs.mpvScripts.thumbfast;
      mpris.path = pkgs.mpvScripts.mpris;
      visualizer.path = pkgs.mpvScripts.visualizer;
      auto-sub-sync.path = inputs.mpv-auto-sub-sync.packages.${pkgs.stdenv.hostPlatform.system}.default;
      "mpv-smartcut.lua".path = "${inputs.mpv-smartcut.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/mpv/scripts/mpv-smartcut.lua";
      "short-loop.lua".content = ''
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
    configDir."script-opts/modernz.conf".content = ''
      window_controls=no
      vidscale=no
      sub_margins=no
    '';
  };
}
