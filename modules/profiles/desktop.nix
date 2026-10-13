{inputs, ...}: {
  flake.nixosModules.profile-desktop = {pkgs, ...}: {
    imports = with inputs.self; [
      nixosModules.profile-core
      nixosModules.audio
      nixosModules.helium
      nixosModules.theme
      nixosModules.discord
      nixosModules.scrcpy
      nixosModules.remote-client
      nixosModules.sunshine
      nixosModules.t3code
      wrappers.niri.install
      wrappers.noctalia.install
      wrappers.monstar.install
      wrappers.mpv.install
      wrappers.termfilechooser.install
    ];
    environment.systemPackages = [pkgs.sshfs];
    services.tailscale.extraSetFlags = ["--advertise-exit-node=false"];
    services.udisks2.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel") && action.id.startsWith("org.freedesktop.udisks2.")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
