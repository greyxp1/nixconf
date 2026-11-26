# Drop with alma/laptop: their cache, together with the substituter in laptop's configuration and alma's _cache.nix.
{
  services.harmonia.cache = {
    enable = true;
    signKeyPaths = ["/persistent/secrets/harmonia/cache-priv-key.pem"];
    settings.bind = "127.0.0.1:5000";
  };

  # Expose only the binary cache protocol, not Harmonia's store browsing, logs or metrics.
  services.caddy.virtualHosts."greyxp1.root.sx".extraConfig = ''
    handle_path /nix-cache/* {
      @cache path /nix-cache-info /*.narinfo /nar/*
      handle @cache {
        reverse_proxy 127.0.0.1:5000
      }
      respond 404
    }
  '';
}
