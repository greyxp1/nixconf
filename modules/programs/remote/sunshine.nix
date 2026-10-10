{
  inputs,
  lib,
  ...
}: let
  sunshinePkgs = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux;
  sunshine = sunshinePkgs.sunshine.overrideAttrs (import ./_sunshine.nix {
    inherit lib;
    inherit (inputs) libvirtualhid;
    pkgs = sunshinePkgs;
  });
  displayFor = pkgs:
    pkgs.writeShellApplication {
      name = "sunshine-display";
      runtimeInputs = [pkgs.niri pkgs.jq];
      text = builtins.readFile ./sunshine-display.sh;
    };
in {
  flake.sunshinePackage = sunshine;
  flake.sunshineDisplay = displayFor;
  flake.nixosModules.sunshine = {
    config,
    utils,
    ...
  }: {
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

  flake.nixosModules.sunshine-cuda = {
    config,
    pkgs,
    utils,
    ...
  }: let
    cudaSunshine =
      ((import inputs.sunshine-nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }).sunshine.override {cudaSupport = true;}).overrideAttrs (import ./_sunshine.nix {
        inherit lib;
        inherit (inputs) libvirtualhid;
        pkgs = sunshinePkgs;
        cudaSupport = true;
      });
    display = displayFor pkgs;
    prepCommands = builtins.toJSON [
      {
        do = "${lib.getExe display} start";
        undo = "${lib.getExe display} restore";
      }
    ];
  in {
    imports = [inputs.self.nixosModules.sunshine];
    services.sunshine.package = cudaSunshine;
    environment.systemPackages = [display];
    systemd.user.services.sunshine = {
      environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      serviceConfig = {
        ExecStart = lib.mkOverride 40 (utils.escapeSystemdExecArgs [
          (lib.getExe config.services.sunshine.package)
          "csrf_allowed_origins=https://${config.networking.hostName}.tail1785c.ts.net:47990"
          "global_prep_cmd=${prepCommands}"
        ]);
        ExecStopPost = "-${lib.getExe display} restore";
      };
    };
  };
}
