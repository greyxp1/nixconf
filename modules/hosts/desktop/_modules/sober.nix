{inputs, ...}: {
  imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];
  preservation.preserveAt."/persistent".directories = ["/var/lib/flatpak"];
  environment.sessionVariables.XDG_DATA_DIRS = ["/var/lib/flatpak/exports/share"];
  services.flatpak = {
    enable = true;
    packages = ["org.vinegarhq.Sober"];
    update.onActivation = true;
  };

  programs.niri.settings.window-rules = [
    {
      matches = [{app-id = "^org\\.vinegarhq\\.Sober$";}];
      open-fullscreen = true;
      variable-refresh-rate = true;
    }
  ];
}
