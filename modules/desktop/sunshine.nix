{
  inputs,
  lib,
  pkgs,
  config,
  utils,
  ...
}: let
  cfg = config.services.sunshine;
  sunshinePin = (builtins.fromJSON (builtins.readFile ../../.tack/pins.lock.json)).sunshine;
  ffmpeg = pkgs.fetchzip {
    url = "https://github.com/LizardByte/build-deps/releases/download/v2026.1017.131201/Linux-x86_64-ffmpeg.tar.gz";
    hash = "sha256-ZFtxcQvlC8k4Nv3HOV5CVhV1F8Yz0McJ98oQ6Gs2slU=";
  };
  sunshine = (pkgs.sunshine.override {inherit (cfg) cudaSupport;}).overrideAttrs (final: old: {
    version = "unstable-${builtins.substring 0 7 sunshinePin.rev}";
    src = inputs.sunshine;
    env =
      old.env
      // {
        BUILD_VERSION = final.version;
        COMMIT = sunshinePin.rev;
      };
    ui = old.ui.overrideAttrs (ui: {
      npmDeps = ui.npmDeps.overrideAttrs {
        outputHash = "sha256-eOhQxVEV4Nhps1WzN4igI8xdOjXPvGn/fOFCvGemKjc=";
      };
    });
    preBuild =
      (old.preBuild or "")
      + ''
        # Keep C++ compilation within the build slice's memory budget.
        NIX_BUILD_CORES=$((NIX_BUILD_CORES > 2 ? 2 : NIX_BUILD_CORES))
      '';
    cmakeFlags =
      builtins.filter (flag: !(lib.hasPrefix "-DFFMPEG_PREPARED_BINARIES" flag)) (old.cmakeFlags or [])
      ++ [
        "-DSUNSHINE_ENABLE_TRAY=OFF"
        (lib.cmakeFeature "FFMPEG_PREPARED_BINARIES" "${ffmpeg}")
      ];
    buildInputs = lib.filter (input: !(builtins.elem input [pkgs.qt6.qtbase pkgs.qt6.qtsvg])) old.buildInputs;
    nativeBuildInputs = lib.filter (input: input != pkgs.qt6.wrapQtAppsHook) old.nativeBuildInputs;
    postFixup = lib.optionalString cfg.cudaSupport ''
      wrapProgram $out/bin/sunshine \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.vulkan-loader]}
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
