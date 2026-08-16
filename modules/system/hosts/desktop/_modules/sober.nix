{inputs, ...}: {
  imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];
  environment.variables.XDG_DATA_DIRS = ["/var/lib/flatpak/exports/share"];
  services.flatpak = {
    enable = true;
    packages = ["org.vinegarhq.Sober"];
    update.onActivation = true;
  };

  home-manager.sharedModules = [
    {
      wayland.windowManager.niri.settings._children = [
        {
          window-rule = {
            match._props."app-id" = "^org\\.vinegarhq\\.Sober$";
            open-fullscreen = true;
            variable-refresh-rate = true;
          };
        }
      ];
    }
  ];
}
