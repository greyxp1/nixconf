{
  outputs = {self, ...} @ args: let
    tackInputs = (import ./.tack) {overrides = args.tackOverrides or {};};
    inputs = tackInputs // {inherit self;};
    importTree = import ./lib/import-tree.nix;
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [(importTree ./modules/hosts)];
      _module.args.importTree = importTree;
      systems = ["x86_64-linux"];
      perSystem = {system, ...}: {
        _module.args.pkgs = inputs.nixpkgs.legacyPackages.${system};
        packages.disko = inputs.disko.packages.${system}.disko;
        packages.mpv-smartcut = inputs.mpv-smartcut.packages.${system}.default;
      };
    };
}
