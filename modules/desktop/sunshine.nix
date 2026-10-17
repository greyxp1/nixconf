{
  inputs,
  lib,
  pkgs,
  config,
  utils,
  ...
}: let
  cfg = config.services.sunshine;
  sunshinePkgs =
    if cfg.cudaSupport
    then
      import inputs.sunshine-nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }
    else inputs.sunshine-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  sunshine = (sunshinePkgs.sunshine.override {inherit (cfg) cudaSupport;}).overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        cp -r ${inputs.libvirtualhid}/. third-party/libvirtualhid/
      '';
    preBuild =
      (old.preBuild or "")
      + ''
        # Keep C++ compilation within the build slice's memory budget.
        NIX_BUILD_CORES=$((NIX_BUILD_CORES > 2 ? 2 : NIX_BUILD_CORES))
      '';
    cmakeFlags = (old.cmakeFlags or []) ++ ["-DSUNSHINE_ENABLE_TRAY=OFF"];
    buildInputs = lib.filter (input: !(builtins.elem input [sunshinePkgs.qt6.qtbase sunshinePkgs.qt6.qtsvg])) old.buildInputs;
    nativeBuildInputs = lib.filter (input: input != sunshinePkgs.qt6.wrapQtAppsHook) old.nativeBuildInputs;
    postFixup = lib.optionalString cfg.cudaSupport ''
      wrapProgram $out/bin/sunshine \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [sunshinePkgs.vulkan-loader]}
    '';
  });
in {
  options.services.sunshine.cudaSupport = lib.mkEnableOption "CUDA support for Sunshine";
  config = {
    boot.kernelModules = ["uhid"];
    users.users.grey.extraGroups = ["uinput"];
    services.udev.extraRules = ''
      SUBSYSTEM=="misc", KERNEL=="uhid", MODE="0660", GROUP="uinput", TAG+="seat", TAG+="uaccess", OPTIONS+="static_node=uhid"
    '';
    services.sunshine = {
      enable = true;
      openFirewall = true;
      package = lib.mkDefault sunshine;
    };
    # Preserve configuration edited through Sunshine's web UI.
    systemd.user.services.sunshine.serviceConfig.ExecStart = lib.mkForce (utils.escapeSystemdExecArgs [
      (lib.getExe config.services.sunshine.package)
      "csrf_allowed_origins=https://${config.networking.hostName}.tail1785c.ts.net:47990"
    ]);
  };
}
