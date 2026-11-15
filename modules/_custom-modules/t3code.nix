{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  cfg = config.programs.t3code;
  json = pkgs.formats.json {};
  # Takes precedence over the relay client T3 Code downloads into its data directory.
  relayClientEnv.T3CODE_CLOUDFLARED_PATH = lib.getExe cfg.server.connect.relayClient;
  # The headless server applies settings itself before starting.
  loginSettings = cfg.settings != {} && !cfg.server.enable;
  mergeSettings = name: settings: let
    settingsFile = json.generate "t3code-${name}.json" settings;
  in
    lib.getExe (pkgs.writeShellApplication {
      name = "t3code-${name}-settings";
      runtimeInputs = [pkgs.jq pkgs.coreutils];
      text = ''
        settings="$1"
        mkdir -p "$(dirname "$settings")"
        temporary=$(mktemp "$settings.XXXXXX")
        trap 'rm -f "$temporary"' EXIT
        if [[ -e "$settings" ]]; then
          jq -s '.[0] * .[1]' "$settings" ${settingsFile} > "$temporary"
        else
          cp ${settingsFile} "$temporary"
        fi
        if ! cmp -s "$temporary" "$settings"; then
          mv "$temporary" "$settings"
        fi
      '';
    });
in {
  options.programs.t3code = {
    enable = lib.mkEnableOption "T3 Code";
    package = lib.mkOption {
      type = lib.types.package;
      description = "T3 Code package providing the `t3` CLI and server, optionally with a separate desktop output.";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf json.type;
      default = {};
      description = "Server settings merged into each user's userdata/settings.json before the headless server starts, or at login without it.";
    };
    desktop = {
      enable = lib.mkEnableOption "the T3 Code desktop app";
      package = lib.mkOption {
        type = lib.types.package;
        default = cfg.package.desktop or cfg.package;
        defaultText = lib.literalExpression "config.programs.t3code.package.desktop or config.programs.t3code.package";
        description = "T3 Code desktop package.";
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf json.type;
        default = {};
        description = "Desktop preferences merged into each user's userdata/client-settings.json at login.";
      };
    };
    server = {
      enable = lib.mkEnableOption "the T3 Code headless server as a user service";
      target = lib.mkOption {
        type = lib.types.str;
        default = "default.target";
        example = "graphical-session.target";
        description = "User target that starts and stops the server. Use the graphical session when agents need the desktop.";
      };
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Address on which the server listens.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3773;
        description = "Server port.";
      };
      tailscaleServe = {
        enable = lib.mkEnableOption "Tailscale Serve, exposing the server over HTTPS on the tailnet";
        port = lib.mkOption {
          type = lib.types.port;
          default = 443;
          description = "HTTPS port on the tailnet.";
        };
      };
      connect = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable T3 Connect with a Nix-provided relay client. Authorize each machine once with `t3 connect link`.";
        };
        relayClient = lib.mkPackageOption pkgs "cloudflared" {};
        protocol = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum ["quic" "http2"]);
          default = null;
          example = "http2";
          description = "Relay transport protocol. Use HTTP/2 on networks that block QUIC.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [cfg.package] ++ lib.optional cfg.desktop.enable cfg.desktop.package;
    }
    (lib.mkIf (loginSettings || cfg.desktop.settings != {}) {
      systemd.user.services.t3code-settings = {
        description = "Apply T3 Code settings";
        wantedBy = ["default.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart =
            lib.optional loginSettings "${mergeSettings "server" cfg.settings} %h/.t3/userdata/settings.json"
            ++ lib.optional (cfg.desktop.settings != {}) "${mergeSettings "client" cfg.desktop.settings} %h/.t3/userdata/client-settings.json";
        };
      };
    })
    (lib.mkIf cfg.server.enable {
      systemd.user.services.t3code = {
        description = "T3 Code headless server";
        enableDefaultPath = false;
        wantedBy = [cfg.server.target];
        after = [cfg.server.target];
        partOf = [cfg.server.target];
        serviceConfig = {
          WorkingDirectory = "%h";
          ExecStart = utils.escapeSystemdExecArgs (
            [(lib.getExe' cfg.package "t3") "serve" "--host" cfg.server.host "--port" cfg.server.port]
            ++ lib.optionals cfg.server.tailscaleServe.enable ["--tailscale-serve" "--tailscale-serve-port" cfg.server.tailscaleServe.port]
          );
          ExecStartPre = lib.optional (cfg.settings != {}) "${mergeSettings "server" cfg.settings} %h/.t3/userdata/settings.json";
          Restart = "on-failure";
          RestartSec = 5;
          KillMode = "mixed";
          UMask = "0077";
        };
      };
    })
    (lib.mkIf (cfg.server.enable && cfg.server.connect.enable) {
      # `t3 connect link` also resolves the relay client and offers a download when it finds none.
      environment.variables = relayClientEnv;
      systemd.user.services.t3code.environment =
        relayClientEnv // lib.optionalAttrs (cfg.server.connect.protocol != null) {TUNNEL_TRANSPORT_PROTOCOL = cfg.server.connect.protocol;};
    })
  ]);
}
