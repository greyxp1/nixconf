{...}: {
  services.couchdb = {
    enable = true;
    extraConfigFiles = ["/run/credentials/couchdb.service/couchdb.ini"];
    extraConfig = {
      cluster.n = 1;
      couchdb = {
        single_node = true;
        max_document_size = 50000000;
      };
      chttpd = {
        require_valid_user = true;
        max_http_request_size = 4294967296;
        enable_cors = true;
      };
      chttpd_auth.require_valid_user = true;
      httpd = {
        enable_cors = true;
        "WWW-Authenticate" = "Basic realm=\"couchdb\"";
      };
      cors = {
        origins = "app://obsidian.md,capacitor://localhost,http://localhost";
        credentials = true;
        headers = "accept,authorization,content-type,origin,referer";
        methods = "GET,PUT,POST,HEAD,DELETE";
      };
    };
  };
  preservation.preserveAt."/persistent".directories = [
    {
      directory = "/var/lib/couchdb";
      user = "couchdb";
      group = "couchdb";
    }
  ];
  systemd.services.couchdb = {
    serviceConfig.LoadCredential = "couchdb.ini:/persistent/secrets/couchdb.ini";
    requires = ["preservation.target"];
    after = ["preservation.target"];
    unitConfig.RequiresMountsFor = ["/var/lib/couchdb"];
  };
}
