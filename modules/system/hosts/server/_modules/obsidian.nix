{...}: {
  virtualisation.oci-containers.containers.obsidian = {
    image = "lscr.io/linuxserver/obsidian@sha256:df2e3703e7674032ff84f847e399271d1834deaaa29273b8f71350409753aa86";
    environment = {
      PUID = "1000";
      PGID = "100";
      TZ = "America/Montreal";
      CUSTOM_PORT = "15323";
      CUSTOM_HTTPS_PORT = "15324";
    };
    volumes = [
      "/var/lib/obsidian:/config"
      "/home/grey/Documents/Notes:/notes"
    ];
    extraOptions = [
      "--shm-size=1g"
      "--network=host"
    ];
  };
  preservation.preserveAt."/persistent".directories = [
    {
      directory = "/var/lib/obsidian";
      user = "grey";
      group = "users";
    }
  ];
  systemd.services.docker-obsidian = {
    requires = ["preservation.target"];
    after = ["preservation.target"];
    unitConfig = {
      RequiresMountsFor = ["/var/lib/obsidian" "/home/grey"];
      ConditionPathIsDirectory = "/home/grey/Documents/Notes";
    };
  };
}
