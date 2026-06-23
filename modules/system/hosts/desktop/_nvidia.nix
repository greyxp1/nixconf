{pkgs, lib, ...}: {
  environment.systemPackages = [pkgs.nvidia-vaapi-driver];
  boot = {
    initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
    kernelParams = [
      "nvidia_drm.modeset=1"
      #"nvidia.NVreg_RegistryDwords=PerfLevelSrc=0x2222"
    ];
  };

  services = {
    xserver.videoDrivers = ["nvidia"];
    acpid.enable = lib.mkForce false;
  };

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;
    #nvidiaPersistenced = true;
    powerManagement = {
      enable = true;
      finegrained = false;
    };
  };
}
