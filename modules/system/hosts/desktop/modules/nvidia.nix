{
  flake.nixosModules.nvidia = {config, lib, pkgs, ...}: {
    options.custom.nvidia.enable = lib.mkEnableOption "NVIDIA graphics";
    config = lib.mkIf config.custom.nvidia.enable {
      environment.systemPackages = [pkgs.nvidia-vaapi-driver];

      boot.kernelParams = [
        "nvidia_drm.modeset=1"
        "nvidia.NVreg_RegistryDwords=PerfLevelSrc=0x2222"
      ];

      services = {
        xserver.videoDrivers = ["nvidia"];
        acpid.enable = lib.mkForce false;
      };

      hardware.nvidia = {
        open = true;
        modesetting.enable = true;
        nvidiaSettings = false;
        nvidiaPersistenced = true;
        powerManagement = {
          enable = true;
          finegrained = false;
        };
      };
    };
  };
}
