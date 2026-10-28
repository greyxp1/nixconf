{
  lib,
  nixos,
  ...
}: {
  alma.packages = ["at-spi2-core"];
  alma.services = ["ydotoold.service"];
  environment.variables = {
    YDOTOOL_SOCKET = nixos.environment.variables.YDOTOOL_SOCKET;
  };
  environment.etc =
    {
      "systemd/user/t3code.service" = {
        source = "${nixos.systemd.user.units."t3code.service".unit}/t3code.service";
        mode = "0644";
        replaceExisting = true;
      };
      "systemd/user/graphical-session.target.d/nixconf-t3code.conf" = {
        text = "[Unit]\nWants=t3code.service\n";
        mode = "0644";
        replaceExisting = true;
      };
      "systemd/user/t3code.service.d/environment.conf" = {
        text = ''
          [Service]
          Environment=TUNNEL_TRANSPORT_PROTOCOL=http2
          Environment=NIX_SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt
        '';
        mode = "0644";
        replaceExisting = true;
      };
    }
    // lib.mapAttrs (_: file: {inherit (file) source;})
    (lib.filterAttrs (name: _: lib.hasPrefix "codex/" name || lib.hasPrefix "claude-code/" name) nixos.environment.etc);
  systemd.services.ydotoold = lib.getAttrs ["description" "wantedBy" "partOf" "serviceConfig"] nixos.systemd.services.ydotoold;
}
