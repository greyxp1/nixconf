{inputs, ...}: {
  flake.nixosModules.niri-portal = {
    imports = [inputs.niri-autoselect-portal.nixosModules.default];
    services.niri-autoselect-portal.enable = true;
  };

  flake.homeModules.niri-portal.wayland.windowManager.niri.settings.binds = {
    "Mod+Shift+S" = {set-dynamic-cast-monitor = {};};
    "Mod+Shift+W" = {set-dynamic-cast-window = {};};
  };
}
