{
  config,
  importTree,
  lib,
  ...
}: {
  imports = [
    (importTree ../../core)
    (importTree ../../desktop)
    ./_hardware.nix
    ./_network.nix
  ];

  swapDevices = [
    {
      device = "/persistent/swapfile";
      size = 8192;
    }
  ];

  services.upower.enable = true;
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    grub.enable = true;
  };

  disko.devices.disk.main = {
    content.partitions = {
      bios = {
        size = "1M";
        type = "EF02";
        priority = 1;
      };
      ESP = {
        name = "boot";
        size = "1G";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/boot";
        };
      };
    };
  };

  programs = {
    # nh copies the derivation to the server, and iets writes it only when instantiating, not on eval.
    fish.shellAliases.rebuild = lib.mkForce "tailscale ssh grey@server true && iets build --no-build ${config.programs.nh.flake}#nixosConfigurations.laptop.config.system.build.toplevel && nh os switch --build-host grey@server --use-substitutes";

    # Ironlake only supports GLES 2, so Chromium's GLES 3 initialization fails.
    helium.flags = ["--disable-gpu"];
    noctalia.settings = {
      bar.default = {
        margin_ends = lib.mkForce 32;
        scale = lib.mkForce 1.0;
        start = lib.mkForce [];
      };
      plugin_settings."noctalia/screen_recorder".replay_enabled = lib.mkForce false;
      hooks.started = lib.mkForce ''
        noctalia msg session lock
        systemctl --user start xdg-desktop-portal.service niri-screenshare.service
      '';
    };
  };
}
