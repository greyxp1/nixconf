{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.tlrc;
  format = pkgs.formats.toml {};
  configFile = format.generate "tlrc.toml" cfg.settings;
in {
  options.programs.tlrc = {
    enable = lib.mkEnableOption "tlrc";
    package = lib.mkPackageOption pkgs "tlrc" {};
    settings = lib.mkOption {
      type = format.type;
      default = {};
      description = "tlrc settings.";
    };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Configured tlrc package.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.tlrc.finalPackage = pkgs.symlinkJoin {
      name = "tlrc-configured";
      paths = [cfg.package];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''wrapProgram $out/bin/tldr --add-flags ${lib.escapeShellArg "--config ${configFile}"}'';
      meta = cfg.package.meta;
    };
    environment.systemPackages = [cfg.finalPackage];
  };
}
