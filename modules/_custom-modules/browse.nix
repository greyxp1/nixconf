{
  config,
  lib,
  ...
}: let
  cfg = config.programs.browse;
in {
  options.programs.browse = {
    enable = lib.mkEnableOption "Browse browser automation";
    package = lib.mkOption {
      type = lib.types.package;
      description = "Browse CLI package.";
    };
    settings = {
      window = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum ["current" "separate"]);
        default = null;
        description = "Where agent tabs open. Null uses the extension setting.";
      };
      cursor = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum ["off" "always"]);
        default = null;
        description = "Agent cursor visibility. Null uses the extension setting.";
      };
      humanInput = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Whether input uses human-like pacing. Null uses the extension setting.";
      };
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      internal = true;
      description = "Browse relay environment.";
    };
  };

  config = {
    programs.browse.environment = lib.optionalAttrs cfg.enable (
      lib.optionalAttrs (cfg.settings.window != null) {
        OPENCODE_BROWSER_AGENT_WINDOW = cfg.settings.window;
      }
      // lib.optionalAttrs (cfg.settings.cursor != null) {
        OPENCODE_BROWSER_GHOST_CURSOR =
          if cfg.settings.cursor == "always"
          then "1"
          else "0";
      }
      // lib.optionalAttrs (cfg.settings.humanInput != null) {
        OPENCODE_BROWSER_HUMAN_INPUT =
          if cfg.settings.humanInput
          then "1"
          else "0";
      }
    );
    environment.systemPackages = lib.mkIf cfg.enable [cfg.package];
    environment.sessionVariables = lib.mkIf cfg.enable cfg.environment;
  };
}
