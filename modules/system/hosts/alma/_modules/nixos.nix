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
        xdg.mime.defaultApplications."inode/directory" = "yazi.desktop";
      }
    ];
  };
  extended = base.extendModules {
    modules = with inputs.self.nixosModules; [cli theme t3code helium scrcpy remote-client sunshine];
  };
  nixos = extended.config;
  baseSources = map (definition: definition.file) base.options.environment.systemPackages.definitionsWithLocations;
  packages = lib.concatMap (definition: definition.value) (builtins.filter
    (definition: !(builtins.elem definition.file baseSources))
    extended.options.environment.systemPackages.definitionsWithLocations);
in {
  _module.args.nixos = nixos;
  # Install program additions without replacing Alma's native system tools.
  environment.systemPackages = builtins.filter (package: toString package != toString nixos.services.sunshine.package) packages;
}
