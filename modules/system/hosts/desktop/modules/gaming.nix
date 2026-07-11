{config, ...}: let flakeConfig = config; in {
  flake.nixosModules.gaming = {config, lib, pkgs, ...}: {
    options.custom.gaming.enable = lib.mkEnableOption "gaming setup";
    config = lib.mkIf config.custom.gaming.enable {
      home-manager.users.grey.imports = [flakeConfig.flake.homeProfiles.gaming];
      programs = {
        steam = {
          enable = true;
          remotePlay.openFirewall = true;
          extraCompatPackages = [pkgs.proton-cachyos_x86_64_v3];
        };

        gamemode = {
          enable = true;
          enableRenice = true;
        };

        gamescope = {
          enable = true;
          enableWsi = true;
        };
      };

      hardware.steam-hardware.enable = true;
      services.udev.extraRules = ''
        ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="nvme*n*", \
          ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
        KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
      '';
    };
  };

  flake.homeProfiles.gaming = {pkgs, ...}: let
    commonArgs = ["-f" "-W" "2560" "-H" "1440" "-r" "170"]
    ++ [
      "--force-windows-fullscreen"
      "--force-grab-cursor"
      "--mangoapp"
    ];
    mkGamescope = name: args:
      pkgs.writeShellScriptBin name ''
        export LOW_LATENCY_LAYER=1
        exec gamescope ${pkgs.lib.escapeShellArgs (commonArgs ++ args)} -- gamemoderun "$@"
      '';
  in {
    home.packages = with pkgs; [
      low-latency-layer
      (mkGamescope "comp" ["-w" "2560" "-h" "1440"])
      (mkGamescope "dlss" ["-w" "2560" "-h" "1440" "--framerate-limit" "170"])
      (mkGamescope "fsr" ["-w" "1920" "-h" "1080" "-F" "fsr" "--sharpness" "5" "--framerate-limit" "170"])
    ];
    catppuccin.mangohud.enable = false;
    programs.mangohud = {
      enable = true;
      settings = {
        legacy_layout = false;
        background_alpha = "0";
        fps = true;
        fps_color_change = "F38BA8,F9E2AF,A6E3A1";
        frame_timing = true;
      };
    };
  };
}
