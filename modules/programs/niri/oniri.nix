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
        systemd.user.services.oniri = {
          Unit.Description = "oniri tiling layout helper";
          Unit.After = ["graphical-session.target"];
          Unit.PartOf = ["graphical-session.target"];
          Service.ExecStart = "${oniri}/bin/oniri --tiling-layout --edges-maximizing";
          Service.Restart = "on-failure";
          Install.WantedBy = ["graphical-session.target"];
        };
      }
    ];
  };
}
