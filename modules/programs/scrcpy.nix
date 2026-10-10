{inputs, ...}: {
  flake.nixosModules.scrcpy = inputs.self.scrcpyModule;
  flake.scrcpyModule = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.scrcpy
      pkgs.android-tools
      (pkgs.makeDesktopItem {
        name = "pixel9";
        desktopName = "Pixel 9";
        icon = "scrcpy";
        exec = ''env SDL_APP_ID=pixel9 scrcpy --select-usb --window-title="Pixel 9" --window-width=440 --video-codec=h264 --max-size=2020 --max-fps=120 --video-bit-rate=16M --keyboard=uhid --keep-active'';
        terminal = false;
        categories = ["Utility"];
      })
      (pkgs.lib.hiPrio (pkgs.runCommand "scrcpy-hidden-desktop-entries" {} ''
        mkdir -p "$out/share/applications"
        for name in scrcpy scrcpy-console; do
          printf '[Desktop Entry]\nHidden=true\n' > "$out/share/applications/$name.desktop"
        done
      ''))
    ];
  };
}
