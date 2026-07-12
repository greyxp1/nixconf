{
  flake.nixosModules.mic = {config, lib, pkgs, ...}: let
    rate = 48000;
    stereo = ["FL" "FR"];
    micCard = "AT2005USB";
    micSource = "rnnoise_source";
    headphonesSink = "alsa_output.usb-Audio-Technica_AT2005USB-00.analog-stereo";

    initScript = pkgs.writeShellScript "at2005usb-init" ''
      i=0
      while [ $i -lt 30 ]; do
        ${pkgs.alsa-utils}/bin/aplay -l 2>/dev/null | grep -q ${micCard} && break
        sleep 1
        i=$((i + 1))
      done

      ${pkgs.alsa-utils}/bin/amixer -c ${micCard} sset Speaker 100%
      ${pkgs.alsa-utils}/bin/amixer -c ${micCard} sset Mic playback 0%
      ${pkgs.alsa-utils}/bin/amixer -c ${micCard} sset Mic capture 100%
    '';

    athM20xEq = pkgs.writeText "ath-m20x-autoeq.txt" ''
      Preamp: -8.88 dB
      Filter 1: ON LSC Fc 105.0 Hz Gain 6.2 dB Q 0.70
      Filter 2: ON PK Fc 68.0 Hz Gain -1.6 dB Q 1.88
      Filter 3: ON PK Fc 88.6 Hz Gain -4.1 dB Q 0.72
      Filter 4: ON PK Fc 268.7 Hz Gain 2.7 dB Q 2.43
      Filter 5: ON PK Fc 643.9 Hz Gain -0.7 dB Q 0.79
      Filter 6: ON PK Fc 1790.6 Hz Gain -3.5 dB Q 0.79
      Filter 7: ON PK Fc 3895.8 Hz Gain 5.6 dB Q 3.25
      Filter 8: ON PK Fc 5491.1 Hz Gain 9.0 dB Q 1.86
      Filter 9: ON PK Fc 6800.9 Hz Gain -4.4 dB Q 5.99
      Filter 10: ON HSC Fc 10000.0 Hz Gain -0.4 dB Q 0.70
    '';

    filterChain = args: {
      name = "libpipewire-module-filter-chain";
      flags = ["nofail"];
      inherit args;
    };
  in {
    options.custom.audio.enable = lib.mkEnableOption "desktop audio setup";

    config = lib.mkIf config.custom.audio.enable {
      systemd.services.at2005usb-init = {
        description = "Set AT2005USB hardware mixer levels";
        after = ["sound.target" "pipewire.service" "pipewire-pulse.service" "wireplumber.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = initScript;
        };
      };

      services.pipewire = {
        extraLadspaPackages = [pkgs.rnnoise-plugin];
        extraConfig.pipewire = {
          "50-rnnoise"."context.modules" = [
            (filterChain {
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
                "node.name" = "capture.${micSource}";
                "node.passive" = true;
                "audio.rate" = rate;
              };
              "playback.props" = {
                "node.name" = micSource;
                "media.class" = "Audio/Source";
                "node.description" = "RNNoise Microphone";
                "audio.rate" = rate;
                "priority.session" = 2000;
              };
            })
          ];

          "51-ath-m20x-eq"."context.modules" = [
            (filterChain {
              "node.description" = "ATH-M20x EQ";
              "media.name" = "ATH-M20x EQ";
              "filter.graph" = {
                nodes = [
                  {
                    type = "builtin";
                    name = "eq";
                    label = "param_eq";
                    config.filename = "${athM20xEq}";
                  }
                ];
                inputs = ["eq:In 1" "eq:In 2"];
                outputs = ["eq:Out 1" "eq:Out 2"];
              };
              "capture.props" = {
                "node.name" = "ath_m20x_eq";
                "media.class" = "Audio/Sink";
                "node.description" = "ATH-M20x EQ";
                "audio.rate" = rate;
                "audio.position" = stereo;
                "priority.session" = 2000;
              };
              "playback.props" = {
                "node.name" = "ath_m20x_eq_output";
                "node.passive" = true;
                "target.object" = headphonesSink;
                "audio.rate" = rate;
                "audio.position" = stereo;
              };
            })
          ];
        };
      };
    };
  };
}
