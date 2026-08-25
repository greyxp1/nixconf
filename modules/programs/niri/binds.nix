let
  bind = action: {_props.repeat = false;} // action;
in {
  flake.homeModules.niri-binds = {
    wayland.windowManager.niri.settings.binds = {
      "Mod+Return" = bind {spawn._args = ["kitty"];};
      "Mod+Escape" = bind {spawn._args = ["kitty" "btm"];};
      "Mod+E" = bind {spawn._args = ["kitty" "nu" "-e" "y"];};
      "Mod+B" = bind {spawn = "helium";};
      "Mod+D" = bind {spawn = "discord";};

      "Mod+C" = bind {spawn-sh = "noctalia msg panel-toggle control-center";};
      "Alt+Space" = bind {spawn-sh = "noctalia msg panel-toggle launcher";};
      "Mod+V" = bind {spawn-sh = "noctalia msg panel-toggle clipboard";};
      "Mod+Print" = bind {spawn-sh = "noctalia msg plugin noctalia/screen_recorder:service all replay-save";};

      "XF86AudioRaiseVolume" = bind {spawn-sh = "noctalia msg volume-up";};
      "XF86AudioLowerVolume" = bind {spawn-sh = "noctalia msg volume-down";};
      "XF86AudioMute" = bind {spawn-sh = "noctalia msg media toggle";};

      "Mod+Q" = bind {close-window = {};};
      "Mod+F" = bind {maximize-window-to-edges = {};};
      "Mod+Shift+F" = bind {fullscreen-window = {};};
      "Mod+T" = bind {toggle-window-floating = {};};
      "Mod+R" = bind {switch-preset-column-width = {};};
      "Mod+Tab" = bind {toggle-overview = {};};
      "Print" = bind {screenshot = {};};

      "Mod+H" = bind {focus-column-left = {};};
      "Mod+L" = bind {focus-column-right = {};};
      "Mod+J" = bind {focus-window-or-workspace-down = {};};
      "Mod+K" = bind {focus-window-or-workspace-up = {};};

      "Mod+Shift+H" = bind {move-column-left = {};};
      "Mod+Shift+L" = bind {move-column-right = {};};
      "Mod+Shift+J" = bind {move-window-down = {};};
      "Mod+Shift+K" = bind {move-window-up = {};};

      "Mod+Shift+ctrl+H" = bind {consume-or-expel-window-left = {};};
      "Mod+Shift+ctrl+L" = bind {consume-or-expel-window-right = {};};
      "Mod+Shift+ctrl+J" = bind {move-column-to-workspace-down = {};};
      "Mod+Shift+ctrl+K" = bind {move-column-to-workspace-up = {};};

      "Mod+Shift+WheelScrollUp" = bind {focus-column-left = {};};
      "Mod+Shift+WheelScrollDown" = bind {focus-column-right = {};};
      "Mod+WheelScrollDown" = bind {focus-window-or-workspace-down = {};};
      "Mod+WheelScrollUp" = bind {focus-window-or-workspace-up = {};};
    };
  };
}
