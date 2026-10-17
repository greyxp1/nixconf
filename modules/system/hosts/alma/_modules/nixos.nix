{
  inputs,
  lib,
  pkgs,
  uid,
  ...
}: let
  base = inputs.nixpkgs.lib.nixosSystem {
    inherit pkgs;
    modules = [
      {
        system.stateVersion = "26.11";
        networking.hostName = "alma";
        users.users.grey = {
          inherit uid;
          isNormalUser = true;
        };
        programs.ydotool.group = lib.mkForce "input";
        xdg.mime.defaultApplications."inode/directory" = "yazi.desktop";
      }
    ];
  };
  extended = base.extendModules {
    modules =
      (with inputs.self.nixosModules; [cli git ssh helix lazygit yazi starship theme t3code helium scrcpy remote-client sunshine bottom monstar mpv niri noctalia nushell termfilechooser])
      ++ [
        ({config, ...}: let
          resizeDisk = widget: widget // lib.optionalAttrs ((widget.type or "") == "disk") {ratio = 2;} // lib.optionalAttrs (widget ? child) {child = map resizeDisk widget.child;};
        in {
          options.programs.bottom.settings = lib.mkOption {
            apply = settings:
              lib.recursiveUpdate settings {
                row = map resizeDisk settings.row;
                disk.mount_filter.is_list_ignored = true;
              };
          };
          config = {
            programs.inshellah.extraDirs = ["/run/system-manager/sw/share/inshellah"];
            programs.niri.settings.binds = {
              "Mod+E" = lib.mkForce {
                repeat = false;
                action.spawn = ["monstar" "-e" "yazi"];
              };
              "Mod+Shift+O" = {
                repeat = false;
                action.spawn = "niri-swap-outputs";
              };
            };
            programs.noctalia.settings = {
              bar.default.margin_ends = lib.mkForce 415;
              plugin_settings."noctalia/screen_recorder".video_codec = lib.mkForce "h264";
            };
            home-manager.sharedModules = [
              {
                programs.helix.languages.language-server.nixd.config = {
                  nixpkgs.expr = "import ${pkgs.path} {}";
                  options.nixos.expr =
                    lib.mkForce "(builtins.getFlake \"path:${config.programs.nh.flake}\").systemConfigs.alma.options";
                };
              }
            ];
          };
        })
      ];
  };
  nixos = extended.config;
  baseSources = map (definition: definition.file) base.options.environment.systemPackages.definitionsWithLocations;
  packages = lib.concatMap (definition: definition.value) (builtins.filter
    (definition: !(builtins.elem definition.file baseSources))
    extended.options.environment.systemPackages.definitionsWithLocations);
in {
  _module.args.nixos = nixos;
  alma.activation.finish = lib.mkAfter (lib.concatMapStringsSep "\n" (user: ''
    /usr/sbin/runuser -u ${lib.escapeShellArg user} -- ${nixos.home-manager.users.${user}.home.activationPackage}/activate --driver-version 1
  '') (builtins.attrNames nixos.home-manager.users));
  # Install program additions without replacing Alma's native system tools.
  environment.systemPackages = builtins.filter (package: toString package != toString nixos.services.sunshine.package) packages;
}
