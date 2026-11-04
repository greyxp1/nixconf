{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  cfg = config.programs.niri;
  value = builtins.toJSON;
  arguments = values: lib.concatMapStringsSep " " value (lib.toList values);
  properties = attrs: lib.concatStringsSep " " (lib.mapAttrsToList (name: v: "${name}=${value v}") attrs);
  block = name: args: children: "${value name} ${args} {\n${children}\n}";
  binds = cfg.settings.binds or {};
  bindProperties =
    if binds ? repeat
    then properties {inherit (binds) repeat;}
    else "";
  nodes = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList node attrs);
  node = name: v:
    if builtins.isAttrs v
    then
      if
        builtins.elem name ["position" "default-floating-position"]
        || (name == "variable-refresh-rate" && v ? on-demand)
      then "${value name} ${properties v}"
      else block name "" (nodes v)
    else if builtins.isList v && lib.all builtins.isAttrs v
    then block name "" (lib.concatMapStringsSep "\n" nodes v)
    else "${value name} ${arguments v}";
  rule = name: attrs:
    block name "" (lib.concatStringsSep "\n" (
      (map (v: "match ${properties v}") (attrs.matches or []))
      ++ (map (v: "exclude ${properties v}") (attrs.excludes or []))
      ++ [(nodes (removeAttrs attrs ["matches" "excludes"]))]
    ));
  text = lib.concatStringsSep "\n" ([
      (nodes (removeAttrs cfg.settings ["binds" "outputs" "workspaces" "window-rules" "layer-rules" "spawn-at-startup" "spawn-sh-at-startup"]))
      (block "binds" bindProperties (lib.concatStringsSep "\n" (lib.mapAttrsToList (key: binding:
              block key (properties (removeAttrs binding ["action"])) (nodes binding.action)) (removeAttrs binds ["repeat"]))))
    ]
    ++ (lib.mapAttrsToList (name: v: block "output" (value name) (nodes v)) (cfg.settings.outputs or {}))
    ++ (lib.mapAttrsToList (name: v: block "workspace" (value name) (nodes v)) (cfg.settings.workspaces or {}))
    ++ (map (rule "window-rule") (cfg.settings.window-rules or []))
    ++ (map (rule "layer-rule") (cfg.settings.layer-rules or []))
    ++ (map (v: "spawn-at-startup ${arguments v}") (cfg.settings.spawn-at-startup or []))
    ++ (map (v: "spawn-sh-at-startup ${value v}") (cfg.settings.spawn-sh-at-startup or []))
    ++ [cfg.extraConfig]);
in {
  # Keep Niri's desktop integrations declarative here without inheriting the
  # nixpkgs module's Nautilus and Secret Service defaults.
  disabledModules = ["programs/wayland/niri.nix"];

  options.programs.niri = {
    enable = lib.mkEnableOption "Niri, a scrollable-tiling Wayland compositor";
    package = lib.mkPackageOption pkgs "niri" {};

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.anything;
        options = lib.genAttrs ["window-rules" "layer-rules" "spawn-at-startup" "spawn-sh-at-startup"] (name:
          lib.mkOption {
            type = lib.types.listOf lib.types.anything;
            default = [];
            description = "Niri ${name}.";
          });
      };
      default = {};
      description = "Niri settings. Bindings contain action and optional properties such as repeat.";
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional KDL configuration.";
    };
    configFile = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      internal = true;
      description = "Validated Niri configuration.";
    };
  };
  config = lib.mkIf cfg.enable (lib.mkMerge [
    (import (modulesPath + "/programs/wayland/wayland-session.nix") {
      inherit lib pkgs;
      enableWlrPortal = false;
      enableXWayland = false;
    })
    {
      environment.systemPackages = [cfg.package];
      services.displayManager.sessionPackages = [cfg.package];
      services.displayManager.defaultSession = lib.mkDefault "niri";
      systemd.packages = [cfg.package];

      xdg.portal = {
        enable = lib.mkDefault true;
        config.niri = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.Access" = "gtk";
          "org.freedesktop.impl.portal.FileChooser" = "gtk";
          "org.freedesktop.impl.portal.Notification" = "gtk";
        };
        extraPortals = [pkgs.xdg-desktop-portal-gnome];
      };

      services.gnome.at-spi2-core.enable = lib.mkDefault true;
      programs.niri.configFile = pkgs.runCommand "niri-config.kdl" {} ''
        cp ${pkgs.writeText "niri-config.kdl" text} $out
        ${lib.getExe cfg.package} validate -c $out
      '';
      environment.etc."niri/config.kdl".source = cfg.configFile;
      systemd.user.services.niri = {
        reloadTriggers = [cfg.configFile];
        reloadIfChanged = true;
        enableDefaultPath = false;
        serviceConfig.ExecReload = "${lib.getExe cfg.package} msg action load-config-file";
      };
    }
  ]);
}
