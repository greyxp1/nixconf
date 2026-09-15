{
  flake.homeModules.scrcpy = {pkgs, ...}: {
    home.packages = [pkgs.scrcpy pkgs.android-tools];
    xdg.desktopEntries.pixel9 = {
      name = "Pixel 9";
      icon = "scrcpy";
      exec = ''env SDL_APP_ID=pixel9 scrcpy --select-usb --window-title="Pixel 9" --window-width=440 --video-codec=h264 --max-size=2020 --max-fps=120 --video-bit-rate=16M --keyboard=uhid --keep-active'';
      terminal = false;
      categories = ["Utility"];
    };

    xdg.dataFile."applications/scrcpy.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';
    xdg.dataFile."applications/scrcpy-console.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';
  };
}
