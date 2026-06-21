{
  inputs = {
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    preservation.url = "github:nix-community/preservation";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    import-tree.url = "github:vic/import-tree";
    catppuccin.url = "github:catppuccin/nix";
    noctalia.url = "github:noctalia-dev/noctalia";
    musnix.url = "github:musnix/musnix";
    nyxexprs.url = "github:notashelf/nyxexprs";

    waytator = {
      url = "github:linusammon/waytator/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-yazi-plugins = {
      #url = "github:lordkekz/nix-yazi-plugins";
      url = "github:greyxp1/nix-yazi-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/0403b4b7e8b2612657f0053a4c315e6c43eee9e6";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-nix = {
      url = "git+https://codeberg.org/BANanaD3V/niri-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nsticky = {
      url = "github:lonerOrz/nsticky";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    oniri = {
      url = "github:Antiz96/oniri";
      flake = false;
    };

    helium = {
      url = "gitlab:AlexLov/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-style-plymouth = {
      url = "github:SergioRibera/s4rchiso-plymouth-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [(inputs.import-tree ./modules)];
      systems = ["x86_64-linux"];
    };
}
