{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.helix;
  toml = pkgs.formats.toml {};
  restoreConfigHome = ''
    if [ "''${HELIX_CONFIG_HOME_ACTIVE-}" = 1 ]; then
      if [ "''${HELIX_ORIGINAL_XDG_CONFIG_HOME+x}" ]; then
        export XDG_CONFIG_HOME="$HELIX_ORIGINAL_XDG_CONFIG_HOME"
      else
        unset XDG_CONFIG_HOME
      fi
      unset HELIX_ORIGINAL_XDG_CONFIG_HOME HELIX_CONFIG_HOME_ACTIVE
    fi
  '';
  shell = pkgs.writeShellScript "helix-shell" ''
    ${restoreConfigHome}
    exec ${pkgs.runtimeShell} "$@"
  '';
  tools = pkgs.symlinkJoin {
    name = "helix-tools";
    paths = cfg.extraPackages;
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      for tool in $out/bin/*; do
        wrapProgram "$tool" --run ${lib.escapeShellArg restoreConfigHome}
      done
    '';
  };
  configDir = pkgs.runCommand "helix-config" {} ''
    mkdir -p $out/helix/themes
    ln -s ${toml.generate "helix-config.toml" (lib.recursiveUpdate {
        editor.shell = ["${shell}" "-c"];
      }
      cfg.settings)} $out/helix/config.toml
    ln -s ${toml.generate "helix-languages.toml" cfg.languages} $out/helix/languages.toml
    ${lib.concatMapAttrsStringSep "\n" (name: theme: ''
        ln -s ${toml.generate "${name}.toml" theme} $out/helix/themes/${lib.escapeShellArg "${name}.toml"}
      '')
      cfg.themes}
  '';
in {
  meta.maintainers = [lib.maintainers.greyxp1];

  options.programs.helix = {
    enable = lib.mkEnableOption "Helix editor";
    package = lib.mkPackageOption pkgs "helix" {};
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      visible = false;
      description = "The Helix package with its configuration and extra tools.";
    };
    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to set EDITOR and VISUAL to hx.";
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      example = lib.literalExpression "[ pkgs.marksman ]";
      description = "Packages added to Helix's PATH, such as language servers and formatters.";
    };
    settings = lib.mkOption {
      type = toml.type;
      default = {};
      description = "Helix editor settings.";
    };
    languages = lib.mkOption {
      type = toml.type;
      default = {};
      description = "Helix language server and formatter settings.";
    };
    themes = lib.mkOption {
      type = lib.types.attrsOf toml.type;
      default = {};
      description = "Custom Helix themes.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.helix.finalPackage = pkgs.symlinkJoin {
      name = "${lib.getName cfg.package}-configured-${lib.getVersion cfg.package}";
      paths = [cfg.package];
      nativeBuildInputs = [pkgs.makeWrapper];
      preferLocalBuild = true;
      postBuild = ''
        wrapProgram $out/bin/hx \
          --run 'if [ "''${XDG_CONFIG_HOME+x}" ]; then export HELIX_ORIGINAL_XDG_CONFIG_HOME="$XDG_CONFIG_HOME"; else unset HELIX_ORIGINAL_XDG_CONFIG_HOME; fi' \
          --set XDG_CONFIG_HOME ${configDir} \
          --set HELIX_CONFIG_HOME_ACTIVE 1 \
          ${lib.optionalString (cfg.extraPackages != []) "--prefix PATH : ${tools}/bin"}
      '';
      meta = cfg.package.meta;
    };
    environment.systemPackages = [cfg.finalPackage];
    environment.variables = lib.mkIf cfg.defaultEditor {
      EDITOR = "hx";
      VISUAL = "hx";
    };
  };
}
