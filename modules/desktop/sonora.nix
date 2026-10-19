{inputs, ...}: {
  imports = [inputs.sonora.nixosModules.default];
  programs.sonora = {
    enable = true;
    settings = {
      tray_icon = false;
      provider = "youtube";
      appearance = {
        transparent = true;
        transparency = 0.2;
      };
    };
  };
}
