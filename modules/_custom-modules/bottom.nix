{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.bottom;
  format = pkgs.formats.toml {};
  configFile = format.generate "bottom.toml" cfg.settings;
in {
  options.programs.bottom = {
    enable = lib.mkEnableOption "bottom";
    package = lib.mkPackageOption pkgs "bottom" {};
    settings = lib.mkOption {
      type = format.type;
      default = {};
      description = "bottom settings.";
    };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Configured bottom package.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.bottom.finalPackage = pkgs.symlinkJoin {
      name = "bottom-configured";
      paths = [cfg.package];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''wrapProgram $out/bin/btm --add-flags ${lib.escapeShellArg "--config_location ${configFile}"}'';
      meta = cfg.package.meta;
    };
    environment.systemPackages = [cfg.finalPackage];
  };
}
