{inputs, ...}: {
  flake.nixosModules.audio = {...}: {
    imports = [inputs.musnix.nixosModules.musnix];
    users.users.grey.extraGroups = ["audio"];
    security.rtkit.enable = true;
    musnix.enable = true;
    musnix.rtirq = {
      enable = true;
      nameList = "usb";
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      extraConfig.pipewire."99-lowlatency"."context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 128;
        "default.clock.min-quantum" = 64;
        "default.clock.max-quantum" = 512;
      };
      wireplumber.extraConfig."10-disable-hw-volume"."monitor.alsa.rules" = [
        {
          matches = [{"device.name" = "~alsa_card.*";}];
          actions.update-props."api.alsa.soft-mixer" = true;
        }
      ];
    };
  };
}
