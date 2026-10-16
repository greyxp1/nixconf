{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.helix;
in
{
  meta.maintainers = [ lib.maintainers.greyxp1 ];

  options.programs.helix = {
    enable = lib.mkEnableOption "Helix editor";
    package = lib.mkPackageOption pkgs "helix" { };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      visible = false;
      description = "The Helix package with extra packages available on PATH.";
    };
    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to set EDITOR and VISUAL to hx.";
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.marksman ]";
      description = "Packages added to Helix's PATH, such as language servers and formatters.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.helix.finalPackage =
      if cfg.extraPackages == [ ] then
        cfg.package
      else
        pkgs.symlinkJoin {
          name = "${lib.getName cfg.package}-configured-${lib.getVersion cfg.package}";
          paths = [ cfg.package ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          preferLocalBuild = true;
          postBuild = ''
            wrapProgram $out/bin/hx --suffix PATH : ${lib.escapeShellArg (lib.makeBinPath cfg.extraPackages)}
          '';
          meta = cfg.package.meta;
        };
    environment.systemPackages = [ cfg.finalPackage ];
    environment.variables = lib.mkIf cfg.defaultEditor {
      EDITOR = "hx";
      VISUAL = "hx";
    };
  };
}
