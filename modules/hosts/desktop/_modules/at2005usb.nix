{
  config,
  lib,
  pkgs,
  ...
}: let
  rate = 48000;
  stereo = ["FL" "FR"];
  micCard = "AT2005USB";
  mixMusic = config.services.lintel.musicMic.enable;
  publicMicSource = "rnnoise_source";
  micSource =
    if mixMusic
    then "rnnoise_filtered"
    else publicMicSource;
  rawMicSource = "alsa_input.usb-Audio-Technica_AT2005USB-00.analog-stereo";
  headphonesSink = "alsa_output.usb-Audio-Technica_AT2005USB-00.analog-stereo";

  initScript = pkgs.writeShellScript "at2005usb-init" ''
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

  nodeRule = prop: node: {
    matches = [{"node.name" = node;}];
    actions.update-props.${prop} = true;
  };
in {
  services.udev.extraRules = ''
    SUBSYSTEM=="sound", KERNEL=="controlC*", ATTRS{id}=="${micCard}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="at2005usb-init.service"
  '';

  systemd.services.at2005usb-init = {
    description = "Set AT2005USB hardware mixer levels";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = initScript;
    };
  };

  services.lintel.musicMic = {
    enable = true;
    voiceSource = micSource;
    sourceName = publicMicSource;
  };

  services.pipewire = {
    wireplumber.extraConfig."51-audio-menu-cleanup"."wireplumber.profiles" = lib.optionalAttrs mixMusic {
      main."hardware.bluetooth" = "disabled";
    };

    wireplumber.extraConfig."50-at2005usb-soft-mixer"."monitor.alsa.rules" = [
      {
        matches = [{"device.name" = "alsa_card.usb-Audio-Technica_AT2005USB-00";}];
        actions.update-props."api.alsa.soft-mixer" = true;
      }
    ];

    wireplumber.extraConfig."51-audio-menu-cleanup"."monitor.alsa.rules" =
      (
        if mixMusic
        then [
          {
            matches = [{"node.name" = headphonesSink;}];
            actions.update-props."media.class" = "Audio/Sink/Internal";
          }
          {
            matches = [{"node.name" = rawMicSource;}];
            actions.update-props."media.class" = "Audio/Source/Internal";
          }
          {
            matches = [
              {
                "media.class" = "~^Audio/(Sink|Source)";
                "node.name" = "!~^(${lib.escapeRegex headphonesSink}|${lib.escapeRegex rawMicSource})$";
              }
            ];
            actions.update-props."node.disabled" = true;
          }
        ]
        else map (nodeRule "node.hidden") [headphonesSink rawMicSource]
      )
      ++ map (nodeRule "node.disabled") [
        "alsa_output.pci-0000_07_00.1.hdmi-stereo"
        "alsa_output.pci-0000_09_00.4.iec958-stereo"
        "alsa_input.pci-0000_09_00.4.analog-stereo"
      ];

    extraLadspaPackages = [pkgs.rnnoise-plugin.ladspa pkgs.ladspaPlugins];
    extraConfig.pipewire = {
      "50-rnnoise"."context.modules" = [
        (filterChain {
          "node.description" = "RNNoise Microphone";
          "media.name" = "RNNoise Microphone";
          "filter.graph" = {
            nodes = [
              {
                type = "ladspa";
                name = "rnnoise";
                plugin = "librnnoise_ladspa";
                label = "noise_suppressor_stereo";
                control = {
                  "VAD Threshold (%)" = 85.0;
                  "VAD Grace Period (ms)" = 200.0;
                  "Retroactive VAD Grace (ms)" = 0.0;
                };
              }
              {
                type = "ladspa";
                name = "limiter";
                plugin = "fast_lookahead_limiter_1913";
                label = "fastLookaheadLimiter";
                control = {
                  "Input gain (dB)" = 8.0;
                  "Limit (dB)" = -1.0;
                  "Release time (s)" = 0.15;
                };
              }
            ];
            links = [
              {
                output = "rnnoise:Output (L)";
                input = "limiter:Input 1";
              }
              {
                output = "rnnoise:Output (R)";
                input = "limiter:Input 2";
              }
            ];
            inputs = ["rnnoise:Input (L)" "rnnoise:Input (R)"];
            outputs = ["limiter:Output 1" "limiter:Output 2"];
          };
          "capture.props" =
            {
              "node.name" = "capture.${micSource}";
              "node.passive" = true;
              "audio.rate" = rate;
              "audio.position" = stereo;
            }
            // lib.optionalAttrs mixMusic {
              "target.object" = rawMicSource;
              "node.dont-fallback" = true;
              "node.linger" = true;
            };
          "playback.props" = {
            "node.name" = micSource;
            "media.class" =
              if mixMusic
              then "Audio/Source/Internal"
              else "Audio/Source";
            "node.description" = "RNNoise Microphone";
            "audio.rate" = rate;
            "audio.position" = stereo;
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
}
