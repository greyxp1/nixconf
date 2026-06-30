{inputs, ...}: {
  flake.homeModules.oniri = {pkgs, ...}: let
    oniri = pkgs.rustPlatform.buildRustPackage {
      pname = "oniri";
      version = "0-unstable";
      src = inputs.oniri;
      cargoHash = "sha256-87EeF5fbYH+TQSTKhdidS0dUl7N+N1aMo+QTobaRQXw=";
    };
  in {
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
  };
}
