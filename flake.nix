{
  outputs = {self, ...} @ args: let
    tackInputs = (import ./.tack) {overrides = args.tackOverrides or {};};
    inputs = tackInputs // {inherit self;};
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.wrappers.flakeModules.wrappers (inputs.import-tree ./modules)];
      systems = ["x86_64-linux"];
      perSystem = {system, ...}: {
        _module.args.pkgs = inputs.nixpkgs.legacyPackages.${system};
        packages.disko = inputs.disko.packages.${system}.disko;
      };
    };
}
