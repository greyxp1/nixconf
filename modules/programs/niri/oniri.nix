{inputs, ...}: {
  flake.nixosModules.oniri = {pkgs, ...}: let
    oniri = pkgs.rustPlatform.buildRustPackage {
      pname = "oniri";
      version = "0-unstable";
      src = inputs.oniri;
      cargoHash = "sha256-8DBL5NvKEiQ7Uh4kFhUynSWc39d+nlu86UZYzHXR8yg=";
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
