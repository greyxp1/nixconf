_: {
  flake.nixosModules.starship = _: {
    home-manager = {
      users.grey = _: {
        catppuccin.starship.enable = false;
        programs.starship = {
          enable = true;
          settings = fromTOML (builtins.readFile ./starship.toml);
        };
      };
    };
  };
}
