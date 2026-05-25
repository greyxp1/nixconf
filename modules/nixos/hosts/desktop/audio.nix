{ ... }: {
  flake.nixosModules.desktop-audio = { pkgs, lib, config, ... }: {
    config = lib.mkIf (config.networking.hostName == "desktop") {
      environment.systemPackages = [ pkgs.rnnoise-plugin ];

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        extraLadspaPackages = [ pkgs.rnnoise-plugin ];

        extraConfig.pipewire."50-rnnoise" = {
          "context.modules" = [{
            name = "libpipewire-module-filter-chain";
            flags = [ "nofail" ];
            args = {
              "node.description" = "RNNoise Microphone";
              "media.name" = "RNNoise Microphone";
              "filter.graph" = {
                nodes = [{
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "librnnoise_ladspa";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 85.0;
                    "VAD Grace Period (ms)" = 200.0;
                    "Retroactive VAD Grace (ms)" = 0.0;
                  };
                }];
              };
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
              };
            };
          }];
        };

        extraConfig.pipewire."99-lowlatency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 128;
            "default.clock.min-quantum" = 64;
            "default.clock.max-quantum" = 512;
          };
        };

        wireplumber.extraConfig = {
          "10-disable-hw-volume" = {
            "monitor.alsa.rules" = [{
              matches = [ { "device.name" = "~alsa_card.*"; } ];
              actions.update-props."api.alsa.soft-mixer" = true;
            }];
          };
          "20-default-source" = {
            "wireplumber.settings" = {
              "default.audio.source" = "rnnoise_source";
            };
          };
        };
      };

      systemd.services.set-alsa-levels = {
        description = "Set AT2005USB hardware mixer levels";
        after = [
          "sound.target"
          "pipewire.service"
          "pipewire-pulse.service"
        ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.dash}/bin/dash -c 'until ${pkgs.alsa-utils}/bin/aplay -l 2>/dev/null | grep -q AT2005USB; do sleep 1; done'";
          ExecStart = [
            "${pkgs.alsa-utils}/bin/amixer -c AT2005USB sset Speaker 100%"
            "${pkgs.alsa-utils}/bin/amixer -c AT2005USB sset Mic playback 0%"
            "${pkgs.alsa-utils}/bin/amixer -c AT2005USB sset Mic capture 100%"
          ];
          RemainAfterExit = true;
        };
      };
    };
  };
}
