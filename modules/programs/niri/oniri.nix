{inputs, ...}: {
  flake.nixosModules.oniri = {pkgs, ...}: let
    oniri = pkgs.rustPlatform.buildRustPackage {
      pname = "oniri";
      version = "0-unstable";
      src = inputs.oniri;
      cargoHash = "sha256-50zEsbDP1DlhHr1iAubpDrzLs8FaLOiMuE/k3eE6jQw=";
    };
  in {
    home-manager.sharedModules = [
      {
        home.packages = [oniri];
        wayland.windowManager.niri.settings.spawn-sh-at-startup = [
          {_args = ["oniri --tiling-layout --edges-maximizing"];}
        ];
      }
    ];
  };
}
