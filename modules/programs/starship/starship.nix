{...}: {
  flake.nixosModules.starship = {...}: {
    home-manager = {
      users.grey = {...}: {
        catppuccin.starship.enable = false;
        programs.starship = {
          enable = true;
          settings = fromTOML (builtins.readFile ./starship.toml);
        };
      };
    };
  };
}
