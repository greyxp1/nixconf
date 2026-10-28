{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.claude-code;
  format = pkgs.formats.json {};
in {
  options.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code";
    package = lib.mkPackageOption pkgs "claude-code" {};
    settings = lib.mkOption {
      type = format.type;
      default = {};
      description = "Managed settings that apply to every user and override their own settings.";
    };
    instructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Managed CLAUDE.md loaded for every session.";
    };
    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = {};
      description = "Managed skills, keyed by name.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
    environment.etc =
      lib.optionalAttrs (cfg.settings != {}) {
        "claude-code/managed-settings.json".source = format.generate "managed-settings.json" cfg.settings;
      }
      // lib.optionalAttrs (cfg.instructions != "") {
        "claude-code/CLAUDE.md".text = cfg.instructions;
      }
      // lib.mapAttrs' (name: content:
        lib.nameValuePair "claude-code/.claude/skills/${name}/SKILL.md" {text = content;})
      cfg.skills;
  };
}
