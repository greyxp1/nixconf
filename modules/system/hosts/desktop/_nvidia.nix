{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = [pkgs.nvidia-vaapi-driver];
  boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
  boot.kernelParams = ["nvidia_drm.modeset=1"];
  boot.extraModprobeConfig = "options nvidia NVreg_DynamicPowerManagementVideoMemoryThreshold=0"; # Niri
  services.xserver.videoDrivers = ["nvidia"];
  services.acpid.enable = lib.mkForce false;
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
  };
}
