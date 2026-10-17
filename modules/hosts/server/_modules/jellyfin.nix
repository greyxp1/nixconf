{...}: {
  services.jellyfin = {
    enable = true;
  };
  users.users.jellyfin.extraGroups = ["render" "video"];
  networking.firewall.allowedTCPPorts = [8097 8921];
  preservation.preserveAt."/persistent".directories = [
    {
      directory = "/var/lib/jellyfin";
      user = "jellyfin";
      group = "jellyfin";
    }
    {
      directory = "/var/cache/jellyfin";
      user = "jellyfin";
      group = "jellyfin";
    }
  ];
  systemd.tmpfiles.rules = [
    "Z /var/lib/jellyfin - jellyfin jellyfin -"
    "d /home/grey/Videos 0755 grey users -"
    "d /home/grey/Videos/Movies 0755 grey users -"
    "d /home/grey/Videos/Shows 0755 grey users -"
    "a+ /home/grey/Videos - - - - d:u:jellyfin:r-x"
    "a+ /home/grey/Videos/Movies - - - - d:u:jellyfin:r-x"
    "a+ /home/grey/Videos/Shows - - - - d:u:jellyfin:r-x"
  ];
  systemd.services.jellyfin = {
    requires = ["preservation.target"];
    after = ["preservation.target"];
    unitConfig = {
      RequiresMountsFor = ["/var/lib/jellyfin" "/home/grey/Videos"];
      ConditionPathIsDirectory = "/var/lib/jellyfin/config";
    };
  };
}
