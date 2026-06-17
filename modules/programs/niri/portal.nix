{...}: {
  flake.nixosModules.niri-portal = {...}: {
    #imports = [inputs.niri-autoselect-portal.nixosModules.default];
    #services.niri-autoselect-portal.enable = true;
    xdg.portal.config.niri.default = ["gnome"];
  };
}
