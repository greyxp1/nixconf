_: {
  flake.nixosModules.nvidia = {config, lib, pkgs, ...}: let cfg =
    config.custom.nvidia; in {
    options.custom.nvidia.enable = lib.mkEnableOption "NVIDIA graphics";
    config = lib.mkIf cfg.enable {
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
