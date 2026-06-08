{
  inputs = {
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    preservation.url = "github:nix-community/preservation";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    import-tree.url = "github:vic/import-tree";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v1.0.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ragenix.url = "github:yaxitech/ragenix";
    ragenix.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin.url = "github:catppuccin/nix";
    niri-nix.url = "git+https://codeberg.org/BANanaD3V/niri-nix";
    niri-nix.inputs.nixpkgs.follows = "nixpkgs";
    niri-autoselect-portal.url = "git+https://codeberg.org/debugloop/niri-autoselect-portal.git";
    nsticky.url = "github:lonerOrz/nsticky";
    nsticky.inputs.nixpkgs.follows = "nixpkgs";
    oniri.url = "github:Antiz96/oniri";
    oniri.flake = false;
    noctalia.url = "github:noctalia-dev/noctalia-shell/v5";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";
    helium.url = "github:AlvaroParker/helium-nix";
    helium.inputs.nixpkgs.follows = "nixpkgs";
    nixcord.url = "github:kaylorben/nixcord";
    nixcord.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    musnix.url = "github:musnix/musnix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [(inputs.import-tree ./modules)];
      systems = ["x86_64-linux"];
    };
}
