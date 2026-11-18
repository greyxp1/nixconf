{
  config,
  lib,
  pkgs,
  ...
}: let
  configFile = (pkgs.formats.toml {}).generate "whisrs.toml" {
    general = {
      backend = "groq";
      language = "en";
      overlay = true;
      tray = false;
      notify = true;
      audio_feedback = false;
      remove_filler_words = true;
      llm_post_process = false;
    };
    groq.model = "whisper-large-v3";
  };
in {
  security.nix-secrets.secrets."desktop/whisrs".owner = "grey";
  environment.systemPackages = [pkgs.whisrs];
  programs.niri.settings.binds."Mod+Space" = {
    action.spawn = ["whisrs" "toggle"];
  };
  hardware.uinput.enable = true;
  users.users.grey.extraGroups = ["uinput"];
  systemd.user.tmpfiles.rules = [
    "d %h/.config/whisrs 0700 - - -"
  ];
  systemd.user.services.whisrs = {
    description = "Headless voice dictation";
    after = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];
    path = [pkgs.whisrs pkgs.wl-clipboard config.programs.niri.package];
    restartTriggers = [configFile];
    unitConfig.ConditionPathExists = config.security.nix-secrets.secrets."desktop/whisrs".path;
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/ln -sfn ${configFile} %h/.config/whisrs/config.toml";
      ExecStart = "${lib.getExe' pkgs.whisrs "whisrsd"}";
      EnvironmentFile = config.security.nix-secrets.secrets."desktop/whisrs".path;
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
