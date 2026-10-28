{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.codex;
  format = pkgs.formats.toml {};
  instructionsFile = pkgs.writeText "codex-AGENTS.md" cfg.instructions;
in {
  options.programs.codex = {
    enable = lib.mkEnableOption "Codex";
    package = lib.mkPackageOption pkgs "codex" {};
    settings = lib.mkOption {
      type = format.type;
      default = {};
      description = "System-wide Codex settings.";
    };
    instructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Instructions managed in each Codex home's AGENTS.md.";
    };
    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = {};
      description = "System-wide skills, keyed by name.";
    };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Codex with its managed instructions.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.codex.finalPackage =
      if cfg.instructions == ""
      then cfg.package
      else
        pkgs.symlinkJoin {
          name = "codex-configured";
          paths = [cfg.package];
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/codex --run ${lib.escapeShellArg ''
              codex_home="''${CODEX_HOME:-$HOME/.codex}"
              if [ "$(${pkgs.coreutils}/bin/readlink "$codex_home/AGENTS.md" 2>/dev/null)" != ${lib.escapeShellArg (toString instructionsFile)} ]; then
                ${pkgs.coreutils}/bin/mkdir -p "$codex_home"
                ${pkgs.coreutils}/bin/ln -sfnT ${instructionsFile} "$codex_home/AGENTS.md"
              fi
            ''}
          '';
          meta = cfg.package.meta;
        };
    environment.systemPackages = [cfg.finalPackage];
    environment.etc =
      {
        "codex/config.toml".source = format.generate "codex-system-config.toml" cfg.settings;
      }
      // lib.mapAttrs' (name: content:
        lib.nameValuePair "codex/skills/${name}" {
          source = pkgs.writeTextDir "SKILL.md" content;
        })
      cfg.skills;
  };
}
