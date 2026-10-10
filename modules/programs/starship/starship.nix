{inputs, ...}: {
  flake.wrappers.starship = {wlib, ...}: {
    install.modules.nixos = {
      wrappers.starship.enable = true;
    };
    imports = [wlib.wrapperModules.starship];
    settings = fromTOML (builtins.readFile ./starship.toml);
  };
}
