{
  config,
  lib,
  pkgs,
  ...
}: let
  fuzzel = lib.getExe pkgs.fuzzel;
  clipboard = lib.getExe pkgs.cliphist;
  clipboardPicker = [
    "${pkgs.coreutils}/bin/env"
    "XDG_CONFIG_HOME=/etc/xdg/clipboard-picker"
    (lib.getExe' pkgs.cliphist "cliphist-fuzzel-img")
  ];
  wlPaste = lib.getExe' pkgs.wl-clipboard "wl-paste";
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  niri = lib.getExe config.programs.niri.package;
  opacity = config.programs.monstar.settings.background-opacity;
  wallpaper = ../_assets/wallpaper.jpg;
  audio = "default_output|default_input";
  graphical = {
    after = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];
  };
  clipboardHistory = type:
    graphical
    // {
      description = "Clipboard history for ${type}";
      serviceConfig = {
        ExecStart = "${wlPaste} --type ${type} --watch ${clipboard} store";
        Restart = "on-failure";
      };
    };
  lockAndSuspend = pkgs.writeShellScript "desktop-lock-and-suspend" ''
    ${systemctl} --user start lock.target && exec ${systemctl} suspend
  '';
  powerIcon = path:
    pkgs.runCommandLocal "${baseNameOf path}.svg" {} ''
      sed -E 's/fill="#[[:xdigit:]]{3,8}"/fill="#cdd6f4"/g' \
        ${pkgs.adwaita-icon-theme}/share/icons/Adwaita/symbolic/${path}-symbolic.svg > "$out"
    '';
  sessionAction = action: desktopName: icon: exec:
    pkgs.makeDesktopItem {
      name = "desktop-session-${action}";
      genericName = "Session";
      inherit desktopName exec;
      icon = toString (powerIcon icon);
    };
in {
  imports = [../../_custom-modules/gpu-screen-recorder.nix];

  environment.etc."xdg/clipboard-picker/fuzzel/fuzzel.ini".text = ''
    include=/etc/xdg/fuzzel/fuzzel.ini
    [main]
    line-height=152px
    lines=3
    width=60
  '';
  environment.systemPackages = [
    pkgs.cliphist
    (sessionAction "lock" "Lock" "status/system-lock-screen" "${systemctl} --user start lock.target")
    (sessionAction "suspend" "Lock and suspend" "status/weather-clear-night" "${lockAndSuspend}")
    (sessionAction "logout" "Log out" "actions/system-log-out" "${niri} msg action quit")
    (sessionAction "reboot" "Reboot" "actions/system-reboot" "${systemctl} reboot")
    (sessionAction "shutdown" "Shut down" "actions/system-shutdown" "${systemctl} poweroff")
  ] ++ lib.optional config.programs.yazi.enable (pkgs.linkFarm "fuzzel-yazi-icon" {
    "share/icons/hicolor/scalable/apps/yazi.png" = "${config.programs.yazi.package}/share/pixmaps/yazi.png";
  });
  environment.etc."xdg/fuzzel/fuzzel.ini".text = ''
    [main]
    font=sans-serif:size=13
    line-height=44px
    lines=10
    horizontal-pad=14
    inner-pad=8
    minimal-lines=yes
    namespace=session-clipboard

    [colors]
    background=1e1e2e${lib.fixedWidthString 2 "0" (lib.toHexString (builtins.floor (opacity * 255 + 0.5)))}
    text=cdd6f4ff
    match=cba6f7ff
    selection=313244ff
    selection-text=cdd6f4ff
    selection-match=cba6f7ff
    border=cba6f7ff

    [key-bindings]
    next=Down Control+n Control+j
    prev=Up Control+p Control+k
    execute=Return KP_Enter Control+y Control+l
    cancel=Escape Control+g Control+c Control+bracketleft Control+h
    delete-line-forward=none
    delete-prev=BackSpace
    custom-1=Mod1+1
    custom-10=Mod1+0
  '';

  programs.niri.settings.layer-rules = [
    {
      matches = [{namespace = "^session-(apps|clipboard)$";}];
      geometry-corner-radius = 10;
      background-effect = {
        blur = true;
        xray = false;
      };
    }
  ];

  programs.niri.settings.binds = {
    "Alt+Space".action.spawn = [fuzzel "--namespace=session-apps"];
    "Mod+V".action.spawn =
      lib.optionals (config.services.lintel.enable or false) [
        (lib.getExe config.services.lintel.package)
        "toggle-picker"
        "session-clipboard"
      ]
      ++ clipboardPicker;
    "Mod+Shift+Escape".action.spawn = [fuzzel "--namespace=session-apps" "--search=Session"];
    XF86AudioRaiseVolume = {
      repeat = true;
      action.spawn = [wpctl "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+"];
    };
    XF86AudioLowerVolume = {
      repeat = true;
      action.spawn = [wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
    };
    XF86AudioMute.action.spawn = [(lib.getExe pkgs.playerctl) "play-pause"];
    "Mod+Shift+Print".action.spawn-sh = lib.mkDefault config.programs.gpu-screen-recorder.recording.toggleCommand;
  } // lib.optionalAttrs config.programs.gpu-screen-recorder.replay.enable {
    "Mod+Print".action.spawn = lib.mkDefault [
      "systemctl"
      "--user"
      "kill"
      "--kill-whom=main"
      "--signal=USR1"
      "gpu-screen-recorder.service"
    ];
  };

  programs.gpu-screen-recorder = {
    replay = {
      enable = lib.mkDefault true;
      settings = {
        CODEC = lib.mkDefault "av1";
        REPLAYDURATION = lib.mkDefault "120";
        AUDIO_DEVICE = lib.mkDefault audio;
        OUTPUTDIR = lib.mkDefault "%h/Videos";
      };
    };
    recording = {
      enable = lib.mkDefault true;
      extraArgs = lib.mkDefault ["-a" audio "-bm" "qp" "-ffmpeg-video-opts" "qp=10"];
    };
  };

  services.systemd-lock-handler.enable = true;
  security.pam.services.swaylock = {};

  systemd.user.services = {
    clipboard-history-text = clipboardHistory "text";
    clipboard-history-image = clipboardHistory "image";

    desktop-polkit =
      graphical
      // {
        description = "Desktop polkit authentication agent";
        serviceConfig = {
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
        };
      };

    swaylock = {
      description = "Lock the Wayland session";
      before = ["lock.target" "sleep.target"];
      partOf = ["graphical-session.target" "lock.target"];
      wantedBy = ["lock.target" "sleep.target"];
      onSuccess = ["unlock.target"];
      requisite = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${lib.getExe pkgs.swaylock} --daemonize --image ${wallpaper} --color 1e1e2e";
        Restart = "on-failure";
      };
    };

    desktop-unlock-portals = {
      description = "Restore desktop portals after unlocking";
      wantedBy = ["unlock.target"];
      wants = ["xdg-desktop-portal.service" "niri-screenshare.service"];
      serviceConfig.Type = "oneshot";
      script = "true";
    };
  };
}
