{pkgs, ...}: {
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
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

  hardware = {
    graphics.enable32Bit = true;
    steam-hardware.enable = true;
  };
  services.pipewire.alsa.support32Bit = true;
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="nvme*n*", \
      ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
    KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
  '';

  home-manager.users.grey = {pkgs, ...}: let
    commonArgs = ["-f" "-W" "2560" "-H" "1440" "-r" "170"]
    ++ [
      "--force-windows-fullscreen"
      "--force-grab-cursor"
      "--mangoapp"
    ];
    mkGamescope = name: args:
      pkgs.writeShellScriptBin name ''
        savedLdPreload="$LD_PRELOAD"
        unset LD_PRELOAD

        exec gamescope ${pkgs.lib.escapeShellArgs (commonArgs ++ args)} -- env \
          LD_PRELOAD="$savedLdPreload" \
          gamemoderun "$@"
      '';
  in {
    home.packages = [
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
