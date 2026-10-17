{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.nvidia-vaapi-driver];
  boot.kernelParams = ["nvidia.NVreg_RegistryDwords=PerfLevelSrc=0x2222"];
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-niri.json".text = builtins.toJSON {
    rules = [
      {
        pattern = {
          feature = "procname";
          matches = "niri";
        };
        profile = "niri";
      }
    ];
    profiles = [
      {
        name = "niri";
        settings = [
          {
            key = "GLVidHeapReuseRatio";
            value = 0;
          }
        ];
      }
    ];
  };
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
