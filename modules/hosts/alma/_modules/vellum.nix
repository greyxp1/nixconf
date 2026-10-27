{nixos, ...}: {
  environment.etc = {
    "systemd/user/vellum.service" = {
      source = "${nixos.systemd.user.units."vellum.service".unit}/vellum.service";
      mode = "0644";
      replaceExisting = true;
    };
    "systemd/user/graphical-session.target.d/nixconf-vellum.conf" = {
      text = "[Unit]\nWants=vellum.service\n";
      mode = "0644";
      replaceExisting = true;
    };
  };
}
