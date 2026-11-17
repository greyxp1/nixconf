{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.gpu-screen-recorder;
  portal = cfg.replay.settings.WINDOW == "portal";
  recordingUnit = "gpu-manual-recording.service";
  recordingSocket = ''"$XDG_RUNTIME_DIR/gpu-manual-recording.sock"'';
in {
  options.programs.gpu-screen-recorder.replay = {
    enable = lib.mkEnableOption "the GPU Screen Recorder replay service";
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        CODEC = "hevc";
        REPLAYDURATION = "120";
      };
      description = ''
        Environment settings from upstream's gpu-screen-recorder.env.
        Capture uses the desktop portal unless WINDOW is overridden.
      '';
    };
  };

  options.programs.gpu-screen-recorder.recording = {
    enable = lib.mkEnableOption "on-demand GPU Screen Recorder capture through the desktop portal";
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional GPU Screen Recorder arguments for manual recordings.";
    };
    onSave = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Executable called with the path of a saved manual recording.";
    };
    toggleCommand = lib.mkOption {
      type = lib.types.lines;
      readOnly = true;
      description = "Shell command to start or stop manual recording from a shortcut.";
      default = ''
        if systemctl --user is-active --quiet ${recordingUnit}; then
          exec systemctl --user stop ${recordingUnit}
        fi
        exec systemctl --user start ${recordingUnit}
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.replay.enable || cfg.recording.enable) {
      environment.systemPackages = lib.optional (!cfg.enable) cfg.package;
    })
    (lib.mkIf cfg.replay.enable {
      programs.gpu-screen-recorder.replay.settings.WINDOW = lib.mkDefault "portal";
      xdg.portal.enable = lib.mkIf portal true;
      systemd.packages = [cfg.package];
      systemd.user.services.gpu-screen-recorder = {
        overrideStrategy = "asDropin";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        wants = lib.optional portal "xdg-desktop-portal.service";
        after = ["graphical-session.target"] ++ lib.optional portal "xdg-desktop-portal.service";
        path = [pkgs.bash];
        environment = cfg.replay.settings;
        serviceConfig = {
          EnvironmentFile = "";
          ExecStartPre = ''${pkgs.coreutils}/bin/mkdir -p -- "''${OUTPUTDIR}"'';
        };
      };
    })
    (lib.mkIf cfg.recording.enable {
      xdg.portal.enable = true;
      systemd.user.services.gpu-manual-recording = {
        description = "GPU Screen Recorder manual recording";
        partOf = ["graphical-session.target"];
        after = ["xdg-desktop-portal.service"];
        wants = ["xdg-desktop-portal.service"];
        serviceConfig.KillSignal = "SIGINT";
        script = ''
          exec ${lib.getExe cfg.package} -v no -w portal ${lib.escapeShellArgs cfg.recording.extraArgs} \
            -restore-portal-session yes \
            -portal-session-token-filepath "$HOME/.config/gpu-screen-recorder/manual-restore-token" \
            -ipc ${recordingSocket} \
            -o "$HOME/Videos/Video_$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S-%N).mp4"
        '';
        preStop = lib.optionalString (cfg.recording.onSave != null) ''
          file=$(${lib.getExe' cfg.package "gsr-cli"} -ipc ${recordingSocket} stop) || exit 0
          exec ${lib.escapeShellArg (toString cfg.recording.onSave)} "$file"
        '';
      };
    })
  ];
}
