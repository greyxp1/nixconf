{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.nvidia-vaapi-driver];
  boot.kernelParams = ["nvidia.NVreg_RegistryDwords=PerfLevelSrc=0x2222"];
  hardware.nvidia = {
    branch = "latest";
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
