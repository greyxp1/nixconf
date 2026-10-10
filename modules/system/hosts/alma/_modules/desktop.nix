{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./core.nix
    ./niri.nix
    ./noctalia.nix
    ./sunshine.nix
    ./session.nix
    inputs.self.scrcpyModule
    inputs.self.remoteClientModule
  ];
  environment.etc = {
    "xdg/mimeapps.list".text = inputs.self.browserMimeDefaults + "inode/directory=yazi.desktop\n";
    "xdg/gtk-3.0/settings.ini".text = inputs.self.gtkSettings;
  };
  environment.variables = inputs.self.cursorSettings;
  environment.pathsToLink = ["/share/icons"];
  environment.systemPackages =
    inputs.self.themePackages pkgs
    ++ [
      pkgs.jetbrains-mono
      pkgs.nerd-fonts.symbols-only
      inputs.mpv-smartcut.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ map (wrapper: wrapper.wrap {inherit pkgs;}) (with inputs.self.wrappers; [
      monstar
      helium
      mpv
      yazi
    ]);
}
