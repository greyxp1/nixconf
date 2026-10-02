let
  flake = builtins.getFlake "path:/home/grey/Projects/nixconf";
in
  flake.lib.mkAlmaSystemConfig {
    uid = builtins.fromJSON (builtins.getEnv "NIXCONF_UID");
    gid = builtins.fromJSON (builtins.getEnv "NIXCONF_GID");
    primaryGroup = builtins.getEnv "NIXCONF_PRIMARY_GROUP";
  }
