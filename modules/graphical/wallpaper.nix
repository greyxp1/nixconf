{inputs, ...}: {
  imports = [inputs.rustbg.nixosModules.default];
  services.rustbg = {
    enable = true;
    wallpapers = {
      wallpaper.image = ./_assets/wallpaper.jpg;
      backdrop = {
        image = ./_assets/wallpaper.jpg;
        blur = 7;
      };
    };
  };
  programs.niri.settings.layer-rules = [
    {
      matches = [{namespace = "^rustbg-backdrop$";}];
      place-within-backdrop = true;
    }
  ];
}
