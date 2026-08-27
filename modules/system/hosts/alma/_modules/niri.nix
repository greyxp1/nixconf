{lib, ...}: {
  wayland.windowManager.niri.settings.binds."Mod+E" = lib.mkForce {
    _props.repeat = false;
    spawn._args = ["kitty" "yazi"];
  };
}
