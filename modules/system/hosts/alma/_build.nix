let
  flake = builtins.getFlake ("path:" + builtins.getEnv "NIXCONF_REPO");
in
  flake.lib.mkAlmaSystemConfig {
    uid = builtins.fromJSON (builtins.getEnv "NIXCONF_UID");
    gid = builtins.fromJSON (builtins.getEnv "NIXCONF_GID");
    primaryGroup = builtins.getEnv "NIXCONF_PRIMARY_GROUP";
    flakeLocation = builtins.getEnv "NIXCONF_REPO";
  }
