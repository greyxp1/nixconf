{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.mpv;
  settings =
    lib.generators.toKeyValue {
      mkKeyValue = key: v: "${key}=${
        if builtins.isBool v
        then lib.boolToYesNo v
        else toString v
      }";
    }
    cfg.settings;
in {
  options.programs.mpv = {
    enable = lib.mkEnableOption "MPV";
    package = lib.mkPackageOption pkgs "mpv" {};
    settings = lib.mkOption {
      type = with lib.types; attrsOf (oneOf [str int float bool]);
      default = {};
      description = "Global MPV settings.";
    };
    bindings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Global input bindings.";
    };
    scripts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "MPV script packages.";
    };
    scriptOpts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = {};
      description = "Options for each script.";
    };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "MPV with its scripts.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.mpv.finalPackage = cfg.package.override (previous: {scripts = (previous.scripts or []) ++ cfg.scripts;});
    environment.systemPackages = [cfg.finalPackage];
    environment.etc =
      {
        "mpv/mpv.conf".text = settings;
        "mpv/input.conf".text = lib.concatStringsSep "\n" (lib.mapAttrsToList (key: command: "${key} ${command}") cfg.bindings);
      }
      // lib.mapAttrs' (name: opts:
        lib.nameValuePair "mpv/script-opts/${name}.conf" {
          text = lib.generators.toKeyValue {} opts;
        })
      cfg.scriptOpts;
  };
}
