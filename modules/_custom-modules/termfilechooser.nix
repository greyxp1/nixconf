{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.xdg.portal.termfilechooser;
  configFile = pkgs.writeText "termfilechooser.ini" (lib.generators.toINI {} cfg.settings);
in {
  options.xdg.portal.termfilechooser = {
    enable = lib.mkEnableOption "terminal file chooser portal";
    package = lib.mkPackageOption pkgs "xdg-desktop-portal-termfilechooser" {};
    settings = lib.mkOption {
      type = with lib.types; attrsOf (attrsOf (oneOf [str int bool]));
      default = {};
      description = "Terminal file chooser settings.";
    };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Configured portal backend.";
    };
  };
  config = lib.mkIf cfg.enable {
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [cfg.finalPackage];
    xdg.portal.termfilechooser.finalPackage = pkgs.symlinkJoin {
      name = "termfilechooser-configured";
      paths = [cfg.package];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/libexec/xdg-desktop-portal-termfilechooser --add-flags ${lib.escapeShellArg "--config ${configFile}"}
        for directory in share/dbus-1 lib/systemd share/systemd; do
          if [ -d ${cfg.package}/$directory ]; then
            rm -rf $out/$directory
            mkdir -p $out/$(dirname "$directory")
            cp -rL ${cfg.package}/$directory $out/$directory
            chmod -R u+w $out/$directory
          fi
        done
        for file in $out/share/dbus-1/services/*.service $out/lib/systemd/user/*.service $out/share/systemd/user/*.service; do
          [ -e "$file" ] || continue
          substituteInPlace "$file" --replace-quiet ${cfg.package} "$out"
        done
      '';
      meta = cfg.package.meta;
    };
  };
}
