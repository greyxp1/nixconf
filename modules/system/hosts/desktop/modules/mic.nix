_: {
  flake.nixosModules.mic = {config, lib, pkgs, ...}: let
    cfg = config.custom.audio;
    initScript = pkgs.writeTextFile {
      name = "at2005usb-init";
      executable = true;
      text = ''
        #!${pkgs.dash}/bin/dash
        i=0
        while [ $i -lt 30 ]; do
          ${pkgs.alsa-utils}/bin/aplay -l 2>/dev/null | grep -q AT2005USB && break
          sleep 1
          i=$((i + 1))
        done
        ${pkgs.alsa-utils}/bin/amixer -c AT2005USB sset Speaker    100%
        ${pkgs.alsa-utils}/bin/amixer -c AT2005USB sset Mic playback  0%
        ${pkgs.alsa-utils}/bin/amixer -c AT2005USB sset Mic capture 100%
      '';
    };
  in {
    options.custom.audio.enable = lib.mkEnableOption "desktop audio setup";

    config = lib.mkIf cfg.enable {
      systemd.services.at2005usb-init = {
        description = "Set AT2005USB hardware mixer levels";
        after = ["sound.target" "pipewire.service" "pipewire-pulse.service" "wireplumber.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${initScript}";
        };
      };

      services.pipewire = {
        extraLadspaPackages = [pkgs.rnnoise-plugin];
        extraConfig.pipewire."50-rnnoise"."context.modules" = [
          {
            name = "libpipewire-module-filter-chain";
            flags = ["nofail"];
            args = {
              "node.description" = "RNNoise Microphone";
              "media.name" = "RNNoise Microphone";
              "filter.graph".nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "librnnoise_ladspa";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 85.0;
                    "VAD Grace Period (ms)" = 200.0;
                    "Retroactive VAD Grace (ms)" = 0.0;
                  };
                }
              ];
              "capture.props" = {
                "node.name" = "capture.rnnoise_source";
                "node.passive" = true;
                "audio.rate" = 48000;
              };
              "playback.props" = {
                "node.name" = "rnnoise_source";
                "media.class" = "Audio/Source";
                "node.description" = "RNNoise Microphone";
                "audio.rate" = 48000;
                "priority.session" = 2000;
              };
            };
          }
        ];
      };
    };
  };
}
