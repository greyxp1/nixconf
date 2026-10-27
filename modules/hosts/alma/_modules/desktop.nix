{
  lib,
  nixos,
  ...
}: {
  imports = [
    ./core.nix
    ./t3code.nix
    ./helium.nix
    ./niri.nix
    ./noctalia.nix
    ./sunshine.nix
    ./vellum.nix
    ./session.nix
  ];
  environment.etc =
    {
      "xdg/gtk-3.0/settings.ini".text = nixos.environment.etc."xdg/gtk-3.0/settings.ini".text;
      "xdg/gtk-4.0/settings.ini".text = nixos.environment.etc."xdg/gtk-4.0/settings.ini".text;
    }
    // lib.mapAttrs (_: file: {inherit (file) source;})
    (lib.filterAttrs (name: _: lib.hasPrefix "mpv/" name) nixos.environment.etc);
  environment.systemPackages = nixos.fonts.packages;
  environment.variables = {
    inherit (nixos.environment.sessionVariables) XCURSOR_THEME XCURSOR_SIZE;
  };
  environment.pathsToLink = ["/share/themes" "/share/icons"];
}
