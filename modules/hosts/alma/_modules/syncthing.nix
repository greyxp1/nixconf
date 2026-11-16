{
  lib,
  nixos,
  ...
}: {
  # Runs the shared Syncthing service natively, as system-manager has no Syncthing module.
  systemd.services = lib.genAttrs ["syncthing" "syncthing-init"] (name: let
    service = nixos.systemd.services.${name};
  in {
    inherit (service) description after requires wantedBy;
    serviceConfig = service.serviceConfig // {PrivateUsers = false;};
    # system-manager sets PATH itself.
    environment = lib.filterAttrs (name: value: name != "PATH" && value != null) service.environment;
  });
  systemd.tmpfiles.settings.syncthing =
    nixos.systemd.tmpfiles.settings.syncthing
    // {
      # Create the parent as grey so tmpfiles can safely reach the notes folder.
      "/home/grey/Documents".d = {
        user = "grey";
        group = "users";
        mode = "0755";
      };
    };
}
