services: {lib, ...}: {
  environment.etc =
    lib.mapAttrs' (name: unit:
      lib.nameValuePair "systemd/user/${name}.service" {
        text = lib.generators.toINI {} unit;
        mode = "0644";
        replaceExisting = true;
      })
    services
    // lib.mapAttrs' (name: unit:
      lib.nameValuePair "systemd/user/${unit.Install.WantedBy}.d/nixconf-${name}.conf" {
        text = "[Unit]\nWants=${name}.service\n";
        mode = "0644";
        replaceExisting = true;
      }) (lib.filterAttrs (_: unit: unit ? Install.WantedBy) services);
}
