{
  hardware.graphics.enable = true;
  services = {
    udisks2.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
    };
  };

  security = {
    rtkit.enable = true;
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel") && action.id.startsWith("org.freedesktop.udisks2.")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
