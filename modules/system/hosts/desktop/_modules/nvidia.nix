{
  inputs,
  lib,
  pkgs,
  ...
}: let
  cudaSunshine = ((import inputs.sunshine-nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  }).sunshine.override {cudaSupport = true;}).overrideAttrs (old: {
    patches = (old.patches or []) ++ [../../../../programs/sunshine-keyboard.patch];
  });
in {
  environment.systemPackages = [pkgs.nvidia-vaapi-driver];
  systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  services.sunshine.package = cudaSunshine;
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
