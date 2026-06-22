{inputs, ...}: {
  flake.nixosModules.oniri = {pkgs, ...}: let
    oniri = pkgs.rustPlatform.buildRustPackage {
      pname = "oniri";
      version = "0-unstable";
      src = inputs.oniri;
      cargoHash = "sha256-8tMWDPJqbhzG06JlmcT/1QpOX3550Eb7ScR+tcHa8+M=";
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
