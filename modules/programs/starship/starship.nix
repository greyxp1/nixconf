{...}: {
  flake.nixosModules.shell = {...}: {
    home-manager = {
      catppuccin.starship.enable = false;
      users.grey = {...}: {
        programs.starship = {
          enable = true;
          settings = fromTOML (builtins.readFile ./starship.toml);
        };
      };
    };
  };
}
