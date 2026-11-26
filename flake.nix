{
  outputs = {self, ...} @ args: let
    tackInputs = (import ./.tack) {overrides = args.tackOverrides or {};};
    inputs = tackInputs // {inherit self;};
    importTree = import ./lib/import-tree.nix;
    system = "x86_64-linux";
  in {
    # Drop with laptop: its entry in this host list.
    nixosConfigurations = inputs.nixpkgs.lib.genAttrs ["desktop" "generic" "laptop" "server"] (hostName:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs importTree;};
        modules = [
          {networking.hostName = hostName;}
          (./modules/hosts + "/${hostName}/configuration.nix")
        ];
      });
    packages.${system} = {
      disko = inputs.disko.packages.${system}.disko;
      mpv-splice = inputs.mpv-splice.packages.${system}.default;
      # Drop with alma: install-alma.sh runs System Manager from this package, also drop its .tack/pins.toml pin.
      system-manager = inputs.system-manager.packages.${system}.default;
    };
    # Drop with alma: its System Manager configuration.
    inherit (import ./modules/hosts/alma/configuration.nix {inherit inputs;}) lib systemConfigs;
  };
}
