{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  cfg = config.programs.t3code;
  server = config.services.t3code;
  json = pkgs.formats.json {};
  mergeSettings = name: settings: let
    settingsFile = json.generate "t3code-${name}.json" settings;
  in pkgs.writeShellApplication {
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
  };
in {
  options = {
    programs.t3code = {
      enable = lib.mkEnableOption "the T3 Code CLI";
      package = lib.mkOption {
        type = lib.types.package;
        description = "T3 Code CLI/server package with a separate desktop output.";
      };
      desktop = {
        enable = lib.mkEnableOption "the T3 Code desktop app";
        package = lib.mkOption {
          type = lib.types.package;
          default = cfg.package.desktop;
          defaultText = lib.literalExpression "config.programs.t3code.package.desktop";
          description = "T3 Code desktop package.";
        };
      };
      clientSettings = lib.mkOption {
        type = lib.types.attrsOf json.type;
        default = {};
        description = "Desktop preferences merged into each user's client-settings.json at login.";
      };
    };
    services.t3code = {
      enable = lib.mkEnableOption "the T3 Code headless server";
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
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = ".t3";
        description = "T3 Code data directory, relative to the user's home unless absolute.";
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf json.type;
        default = {};
        description = "Server settings merged into userdata/settings.json before starting.";
      };
    };
  };

  config = lib.mkMerge [
    {
      programs.t3code.enable = lib.mkDefault (server.enable || cfg.desktop.enable);
    }
    (lib.mkIf cfg.enable {
      environment.systemPackages = [cfg.package];
    })
    (lib.mkIf cfg.desktop.enable {
      environment.systemPackages = [cfg.desktop.package];
    })
    (lib.mkIf ((cfg.enable || cfg.desktop.enable) && cfg.clientSettings != {}) {
      systemd.user.services.t3code-settings = {
        description = "Apply T3 Code desktop settings";
        wantedBy = ["default.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = ''${lib.getExe (mergeSettings "client" cfg.clientSettings)} %h/.t3/userdata/client-settings.json'';
        };
      };
    })
    (lib.mkIf server.enable {
      systemd.user.services.t3code = {
        description = "T3 Code headless server";
        enableDefaultPath = false;
        wantedBy = [server.target];
        after = [server.target];
        partOf = [server.target];
        serviceConfig = {
          WorkingDirectory = "%h";
          ExecStart = utils.escapeSystemdExecArgs (
            [(lib.getExe cfg.package) "serve" "--host" server.host "--port" server.port]
            ++ lib.optionals (server.dataDir != ".t3") ["--base-dir" server.dataDir]
          );
          ExecStartPre = lib.optional (server.settings != {})
            (utils.escapeSystemdExecArgs [(lib.getExe (mergeSettings "server" server.settings)) "${server.dataDir}/userdata/settings.json"]);
          Restart = "on-failure";
          RestartSec = 5;
          KillMode = "mixed";
          UMask = "0077";
        };
      };
    })
  ];
}
