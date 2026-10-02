{inputs, ...}: {
  flake.nixosModules.starship = {
    imports = [inputs.self.wrappers.starship.install];
    wrappers.starship.enable = true;
  };

  flake.wrappers.starship = {wlib, ...}: {
    imports = [wlib.wrapperModules.starship];
    settings = fromTOML (builtins.readFile ./starship.toml);
  };
}
