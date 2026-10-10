{inputs, ...}: {
  flake.nixosModules.profile-desktop = {pkgs, ...}: {
    environment.systemPackages = [pkgs.sshfs];
    services.tailscale.extraSetFlags = ["--advertise-exit-node=false"];
    wrappers.nushell.integrations.yazi.enable = true;
    imports = with inputs.self.nixosModules; [
      profile-core
      audio
      niri
      noctalia
      monstar
      helium
      mpv
      theme
      yazi
      scrcpy
      remote-client
    ];
  };
}
