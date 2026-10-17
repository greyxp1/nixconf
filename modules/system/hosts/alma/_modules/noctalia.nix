{nixos, ...}: {
  imports = [
    (import ./_userServices.nix {
      noctalia = {
        Unit = {
          After = "graphical-session.target";
          PartOf = "graphical-session.target";
        };
        Service = nixos.systemd.user.services.noctalia.serviceConfig;
        Install.WantedBy = "graphical-session.target";
      };
    })
  ];
}
