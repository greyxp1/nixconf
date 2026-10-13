{
  inputs,
  nixos,
  pkgs,
  ...
}: {
  imports = [
    ./core.nix
    ./t3code.nix
    ./helium.nix
    ./niri.nix
    ./noctalia.nix
    ./sunshine.nix
    ./session.nix
  ];
  environment.etc = {
    "xdg/gtk-3.0/settings.ini".text = nixos.environment.etc."xdg/gtk-3.0/settings.ini".text;
    "xdg/gtk-4.0/settings.ini".text = nixos.environment.etc."xdg/gtk-4.0/settings.ini".text;
  };
  environment.variables = {
    inherit (nixos.environment.sessionVariables) XCURSOR_THEME XCURSOR_SIZE;
  };
  environment.pathsToLink = ["/share/themes" "/share/icons"];
  environment.systemPackages =
    [
      pkgs.jetbrains-mono
      pkgs.nerd-fonts.symbols-only
      inputs.mpv-smartcut.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ map (wrapper: wrapper.wrap {inherit pkgs;}) (with inputs.self.wrappers; [
      monstar
      mpv
    ]);
}
