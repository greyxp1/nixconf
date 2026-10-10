{
  pkgs,
  inputs,
  lib,
  ...
}: let
  noctalia = inputs.self.wrappers.noctalia.wrap {
    inherit pkgs;
    settings = {
      bar.default.margin_ends = lib.mkForce 415;
      plugin_settings."noctalia/screen_recorder".video_codec = lib.mkForce "h264";
    };
  };
in {
  imports = [
    (import ./_userServices.nix {
      noctalia = {
        Unit = {
          After = "graphical-session.target";
          PartOf = "graphical-session.target";
        };
        Service = {
          ExecStart = "${noctalia}/bin/noctalia";
          Restart = "on-failure";
        };
        Install.WantedBy = "graphical-session.target";
      };
    })
  ];
  environment.systemPackages = [noctalia pkgs.gpu-screen-recorder];
}
