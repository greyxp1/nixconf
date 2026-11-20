{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.antigravity-cli;
  format = pkgs.formats.json {};
  gateway = cfg.gateway;
  hasInstructions = cfg.instructions != "";
  hasSkills = cfg.skills != {};
  needsWrapper = gateway != null || hasInstructions || hasSkills;
  instructionsFile = pkgs.writeText "antigravity-AGENTS.md" cfg.instructions;
  skillsDir = pkgs.linkFarm "antigravity-skills" (
    lib.mapAttrsToList (name: content: {
      name = "${name}/SKILL.md";
      path = pkgs.writeText "${name}-SKILL.md" content;
    })
    cfg.skills
  );
  skillsFile = format.generate "antigravity-skills.json" {
    entries = [{path = toString skillsDir;}];
  };
  coreutils = pkgs.coreutils;
  customizationsScript = lib.optionalString (hasInstructions || hasSkills) ''
    gemini_dir="$HOME/.gemini"
    expect_gemini_dir=0
    for arg in "$@"; do
      if [ "$expect_gemini_dir" -eq 1 ]; then
        gemini_dir="$arg"
        expect_gemini_dir=0
      else
        case "$arg" in
          --gemini-dir|--gemini_dir)
            expect_gemini_dir=1
            ;;
          --gemini-dir=*|--gemini_dir=*)
            gemini_dir="''${arg#*=}"
            ;;
        esac
      fi
    done
    case "$gemini_dir" in
      /*) ;;
      *) gemini_dir="$HOME/$gemini_dir" ;;
    esac
    config_dir="$gemini_dir/config"
    ${lib.optionalString hasInstructions ''
      if [ "$("${lib.getExe' coreutils "readlink"}" "$config_dir/AGENTS.md" 2>/dev/null)" != ${lib.escapeShellArg (toString instructionsFile)} ]; then
        "${lib.getExe' coreutils "mkdir"}" -p "$config_dir"
        "${lib.getExe' coreutils "ln"}" -sfnT ${lib.escapeShellArg (toString instructionsFile)} "$config_dir/AGENTS.md"
      fi
    ''}
    ${lib.optionalString hasSkills ''
      if [ "$("${lib.getExe' coreutils "readlink"}" "$config_dir/skills.json" 2>/dev/null)" != ${lib.escapeShellArg (toString skillsFile)} ]; then
        "${lib.getExe' coreutils "mkdir"}" -p "$config_dir"
        "${lib.getExe' coreutils "ln"}" -sfnT ${lib.escapeShellArg (toString skillsFile)} "$config_dir/skills.json"
      fi
    ''}
  '';
  gatewayScript = lib.optionalString (gateway != null) ''
    if [ "''${1-}" != "acp" ]; then
      export AGY_LLM_GATEWAY_URL=${lib.escapeShellArg gateway.url}
      export AGY_LLM_GATEWAY_WIRE_PROTOCOL=genai
      export AGY_LLM_GATEWAY_MODELS=${lib.escapeShellArg (lib.concatStringsSep "," gateway.models)}
      AGY_LLM_GATEWAY_API_KEY="$("${lib.getExe' coreutils "cat"}" ${lib.escapeShellArg gateway.apiKeyFile})" || exit 1
      export AGY_LLM_GATEWAY_API_KEY
    fi
  '';
  wrappedPackage = pkgs.symlinkJoin {
    name = "antigravity-cli-configured";
    paths = [cfg.package];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/agy" \
        --run ${lib.escapeShellArg (customizationsScript + gatewayScript)}
    '';
    meta = cfg.package.meta;
  };
in {
  options.programs.antigravity-cli = {
    enable = lib.mkEnableOption "Antigravity CLI";
    package = lib.mkPackageOption pkgs "antigravity-cli" {};
    adminSettings = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf format.type) lib.types.path;
      default = {};
      description = "System-wide Antigravity CLI administrator settings, or the absolute path to a JSON file provisioned at runtime.";
    };
    instructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Instructions managed in each Antigravity config directory's AGENTS.md.";
    };
    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = {};
      description = "Managed skills registered in each Antigravity config directory's skills.json, keyed by name.";
    };
    gateway = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "Base URL of a Gemini-compatible model gateway.";
          };
          apiKeyFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to the gateway API key, read at launch.";
          };
          models = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Model identifiers exposed by the gateway.";
          };
        };
      });
      description = "Gateway settings for the installed agy command.";
    };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Antigravity CLI with its managed configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.antigravity-cli.finalPackage =
      if needsWrapper
      then wrappedPackage
      else cfg.package;
    environment.systemPackages = [cfg.finalPackage];
    environment.etc = lib.optionalAttrs (cfg.adminSettings != {}) {
      "antigravity/admin_settings.json".source =
        if builtins.isAttrs cfg.adminSettings
        then format.generate "antigravity-admin-settings.json" cfg.adminSettings
        else cfg.adminSettings;
    };
  };
}
