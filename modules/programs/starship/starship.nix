{
  flake.homeModules.starship = {
    catppuccin.starship.enable = false;
    programs.starship = {
      enable = true;
      settings = fromTOML (builtins.readFile ./starship.toml);
    };
  };
}
