{config, ...}: {
  security.nix-secrets.secrets.freedns-password = {};
  services.ddclient = {
    enable = true;
    interval = "1min";
    protocol = "freedns";
    server = "freedns.afraid.org";
    username = "greyxp1";
    domains = ["greyxp1.root.sx"];
    usev6 = "";
    passwordFile = config.security.nix-secrets.secrets.freedns-password.path;
  };

  systemd.services.ddclient = {
    after = ["network-online.target" "preservation.target"];
    wants = ["network-online.target"];
    requires = ["preservation.target"];
    unitConfig.ConditionPathExists = config.services.ddclient.passwordFile;
  };
}
