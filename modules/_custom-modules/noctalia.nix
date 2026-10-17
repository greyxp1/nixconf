{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.noctalia;
  format = pkgs.formats.toml {};
  configDir = pkgs.runCommand "noctalia-config" {} ''
    mkdir -p $out/noctalia/palettes
    cp ${format.generate "config.toml" cfg.settings} $out/noctalia/config.toml
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: palette: ''
        cp ${pkgs.writeText "palette.json" (builtins.toJSON palette)} $out/noctalia/palettes/${lib.escapeShellArg name}.json
      '')
      cfg.customPalettes)}
  '';
in {
  options.programs.noctalia = {
    settings = lib.mkOption {
      type = format.type;
      default = {};
      description = "Noctalia defaults. Runtime overrides remain writable.";
    };
    customPalettes = lib.mkOption {
      type = lib.types.attrsOf (pkgs.formats.json {}).type;
      default = {};
      description = "Named colour palettes.";
    };
    package = lib.mkOption {
      apply = package:
        pkgs.symlinkJoin {
          name = "noctalia-configured";
          paths = [package];
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = ''
            ${lib.getExe package} config validate ${configDir}/noctalia/config.toml
            wrapProgram $out/bin/noctalia --set NOCTALIA_CONFIG_HOME ${configDir}
          '';
          meta = package.meta;
        };
    };
  };
}
