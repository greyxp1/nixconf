let
  flake = builtins.getFlake ("path:" + builtins.getEnv "NIXCONF_REPO");
in
  flake.lib.mkAlmaSystemConfig {
    username = builtins.getEnv "NIXCONF_USERNAME";
    uid = builtins.fromJSON (builtins.getEnv "NIXCONF_UID");
    gid = builtins.fromJSON (builtins.getEnv "NIXCONF_GID");
    primaryGroup = builtins.getEnv "NIXCONF_PRIMARY_GROUP";
    homeDirectory = builtins.getEnv "NIXCONF_HOME";
    flakeLocation = builtins.getEnv "NIXCONF_REPO";
  }
