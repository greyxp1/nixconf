{inputs, ...}: {
  imports = [inputs.rustbg.nixosModules.default];
  services.rustbg = {
    enable = true;
    wallpapers = {
      wallpaper.image = ./noctalia/assets/wallpaper.jpg;
      backdrop = {
        image = ./noctalia/assets/wallpaper.jpg;
        blur = 7;
      };
    };
  };
}
