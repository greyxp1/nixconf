{lib, pkgs, ...}: {
  environment.systemPackages = [pkgs.nvidia-vaapi-driver];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;
    powerManagement.enable = true;
  };

  services = {
    xserver.videoDrivers = ["nvidia"];
    acpid.enable = lib.mkForce false;
  };
}
