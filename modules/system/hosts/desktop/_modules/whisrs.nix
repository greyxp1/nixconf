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
  environment.systemPackages = [pkgs.whisrs];
  wrappers.niri.settings.binds."Mod+Space" = _: {
    props.repeat = false;
    content.spawn = ["whisrs" "toggle"];
  };
  hardware.uinput.enable = true;
  users.users.grey.extraGroups = ["uinput"];
  systemd.user.tmpfiles.rules = [
    "d %h/.config/whisrs 0700 - - -"
    "f %h/.config/whisrs/credentials 0600 - - -"
  ];
  systemd.user.services.whisrs = {
    description = "Headless voice dictation";
    after = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];
    path = [pkgs.whisrs pkgs.wl-clipboard config.programs.niri.package];
    restartTriggers = [configFile];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/ln -sfn ${configFile} %h/.config/whisrs/config.toml";
      ExecStart = "${lib.getExe' pkgs.whisrs "whisrsd"}";
      EnvironmentFile = "-%h/.config/whisrs/credentials";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
