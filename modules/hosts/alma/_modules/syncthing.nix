{
  lib,
  nixos,
  ...
}: {
  # Runs the shared Syncthing service natively, as system-manager has no Syncthing module.
  systemd.services = lib.genAttrs ["syncthing" "syncthing-init"] (name: let
    service = nixos.systemd.services.${name};
  in {
    inherit (service) description after requires wantedBy serviceConfig;
    # system-manager sets PATH itself.
    environment = lib.filterAttrs (name: value: name != "PATH" && value != null) service.environment;
  });
  systemd.tmpfiles.settings.syncthing = nixos.systemd.tmpfiles.settings.syncthing;
}
