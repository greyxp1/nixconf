_: {
  flake.homeModules.starship = _: {
    catppuccin.starship.enable = false;
    programs.starship = {
      enable = true;
      settings = fromTOML (builtins.readFile ./starship.toml);
    };
  };
}
