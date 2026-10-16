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
      (with inputs.self.nixosModules; [cli git ssh helix lazygit yazi starship theme t3code helium scrcpy remote-client sunshine])
      ++ [
        ({config, ...}: {
          home-manager.sharedModules = [
            {
              programs.helix.languages.language-server.nixd.config = {
                nixpkgs.expr = "import ${pkgs.path} {}";
                options.nixos.expr =
                  lib.mkForce "(builtins.getFlake \"path:${config.programs.nh.flake}\").systemConfigs.alma.options";
              };
            }
          ];
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
