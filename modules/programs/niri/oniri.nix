{inputs, ...}: {
  flake.nixosModules.oniri = {pkgs, ...}: let
    oniri = pkgs.rustPlatform.buildRustPackage {
      pname = "oniri";
      version = "0-unstable";
      src = inputs.oniri;
      cargoHash = "sha256-vE6wf0eseWuE/z0XjuLBNbjtE37eHUXi6hrT231Qi0U=";
    };
  in {
    home-manager.sharedModules = [
      {
        systemd.user.services.oniri = {
          Install.WantedBy = ["graphical-session.target"];
          Unit = {
            Description = "oniri tiling layout helper";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            ExecStart = "${oniri}/bin/oniri --tiling-layout --edges-maximizing";
            Restart = "on-failure";
          };
        };
      }
    ];
  };
}
