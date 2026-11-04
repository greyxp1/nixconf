{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.gpu-screen-recorder;
  portal = cfg.replay.settings.WINDOW == "portal";
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

  config = lib.mkIf cfg.replay.enable {
    programs.gpu-screen-recorder.replay.settings.WINDOW = lib.mkDefault "portal";
    environment.systemPackages = lib.optional (!cfg.enable) cfg.package;
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
  };
}
