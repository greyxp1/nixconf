{...}: {
  services.ddclient = {
    enable = true;
    interval = "1min";
    protocol = "freedns";
    server = "freedns.afraid.org";
    username = "greyxp1";
    domains = ["greyxp1.root.sx"];
    usev6 = "";
    passwordFile = "/persistent/secrets/freedns-password";
  };

  systemd.services.ddclient = {
    after = ["network-online.target" "preservation.target"];
    wants = ["network-online.target"];
    requires = ["preservation.target"];
    unitConfig.ConditionFileNotEmpty = "/persistent/secrets/freedns-password";
  };
}
