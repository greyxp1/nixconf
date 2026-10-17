{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.monstar;
  configFile = pkgs.writeText "monstar.conf" (lib.concatStringsSep "\n" (lib.mapAttrsToList
    (name: value: "${name} = ${
      if builtins.isBool value
      then lib.boolToString value
      else toString value
    }")
    cfg.settings));
in {
  options.programs.monstar = {
    enable = lib.mkEnableOption "Monstar terminal";
    package = lib.mkOption {
      type = lib.types.package;
      description = "Monstar package.";
    };
    settings = lib.mkOption {
      type = with lib.types; attrsOf (oneOf [str int float bool path]);
      default = {};
      description = "Monstar settings.";
    };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Configured Monstar package.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.monstar.finalPackage = pkgs.symlinkJoin {
      name = "monstar-configured";
      paths = [cfg.package];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/monstar --add-flags ${lib.escapeShellArg "--config ${configFile}"}
        if [ -d ${cfg.package}/share/applications ]; then
          rm -rf $out/share/applications
          cp -rL ${cfg.package}/share/applications $out/share/applications
          chmod -R u+w $out/share/applications
        fi
        for file in $out/share/applications/*.desktop; do
          [ -e "$file" ] || continue
          substituteInPlace "$file" --replace-quiet ${cfg.package} "$out"
        done
      '';
      meta = cfg.package.meta;
    };
    environment.systemPackages = [cfg.finalPackage cfg.package.terminfo];
  };
}
