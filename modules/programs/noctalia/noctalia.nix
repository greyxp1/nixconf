{inputs, ...}: {
  flake.nixosModules.noctalia = {pkgs, ...}: let
    noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    environment.systemPackages = [pkgs.gpu-screen-recorder];
    home-manager.users.grey = {
      imports = [inputs.noctalia.homeModules.default];
      programs.noctalia = {
        enable = true;
        package = noctaliaPkg;
        settings = ./config.toml;
        systemd.enable = true;
      };
      systemd.user.services.noctalia.Service.ExecStartPost = "${pkgs.writeShellScript "noctalia-init-replay" ''
        sleep 5
        ${noctaliaPkg}/bin/noctalia msg scripted-widget screen_recorder focused replay-start
      ''}";
    };
  };
}
