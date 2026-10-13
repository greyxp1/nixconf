{
  lib,
  nixos,
  ...
}: {
  alma.packages = ["at-spi2-core"];
  alma.services = ["t3code.service" "ydotoold.service"];
  environment.variables = {
    OPENCODE_CONFIG = nixos.environment.variables.OPENCODE_CONFIG;
    YDOTOOL_SOCKET = nixos.environment.variables.YDOTOOL_SOCKET;
  };
  environment.etc."codex/config.toml".source = nixos.environment.etc."codex/config.toml".source;
  systemd.services.t3code =
    (lib.getAttrs ["description" "wantedBy" "after" "environment" "serviceConfig"]
      nixos.systemd.services.t3code)
    // {
      environment =
        nixos.systemd.services.t3code.environment
        // {
          TUNNEL_TRANSPORT_PROTOCOL = "http2";
          NIX_SSL_CERT_FILE = "/etc/pki/tls/certs/ca-bundle.crt";
          PATH = lib.mkForce "/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin";
        };
    };
  systemd.services.ydotoold = lib.getAttrs ["description" "wantedBy" "partOf" "serviceConfig"] nixos.systemd.services.ydotoold;
}
