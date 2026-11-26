{
  config,
  lib,
  ...
}: let
  # A new host creates its ID on first start. Add it here from a peer's pending devices or
  # `syncthing device-id --home ~/.config/syncthing`, store its cert.pem and key.pem with
  # `nix-secrets edit syncthing/<host>/{cert,key}`, then rebuild every host.
  devices = {
    # Drop with alma:
    alma = "PTNZ5IT-GV5PIGJ-Z5THHTM-C27MPWU-NEAR3GE-M5C2DF7-RHWYIEW-F3SGHAW";
    desktop = "SZPGBLD-JSMNNQT-FBKOBQ4-2ZTKES4-CWYCHJP-IAX4KC4-AMB2F3Z-ODYBYQL";
    server = "OAETKIB-GLNECRC-YMOWH6H-J4RMOBQ-NUMUFPK-FDPB47E-3EAUTGX-DSSKCAT";
    # Drop with laptop: also secrets/syncthing/laptop.
    laptop = "55HVKIA-5JTEWB7-63HKSBZ-NFWG6AU-2IHWSDB-H5AUQUV-P4CMJ7Q-WSSTLAZ";
    pixel-9 = "O2BEKRC-VAKWYYH-WAW6C2L-WNU37RH-CXOD2GO-JL7OXU2-XDVFJ3A-UMPXNAA";
  };
  host = config.networking.hostName;
  # Every device connects directly to every other, so syncing never waits on one host.
  peers = lib.removeAttrs devices [host];
  notes = "/home/grey/Documents/Notes";
  secrets = config.security.nix-secrets;
  # Listed hosts keep their identity as secrets, so a reinstall keeps the same ID.
  identity = lib.genAttrs ["cert" "key"] (file: "syncthing/${host}/${file}");
  # Drop with alma: the secrets.enable check, since only alma disables nix-secrets.
  storedIdentity = secrets.enable && devices ? ${host};
in {
  security.nix-secrets.secrets = lib.mkIf storedIdentity (lib.genAttrs (lib.attrValues identity) (_: {
    owner = "grey";
    group = "users";
  }));
  systemd.services.syncthing.unitConfig.ConditionPathExists = lib.mkIf (storedIdentity && secrets.activate.method == "systemd") secrets.secrets.${identity.key}.path;
  services.syncthing = {
    enable = true;
    cert = lib.mkIf storedIdentity secrets.secrets.${identity.cert}.path;
    key = lib.mkIf storedIdentity secrets.secrets.${identity.key}.path;
    user = "grey";
    group = "users";
    dataDir = "/home/grey";
    openDefaultPorts = true;
    settings = {
      # Tailnet addresses first, so hosts connect directly wherever they are.
      devices = lib.mapAttrs (name: id: {
        inherit id;
        addresses = ["tcp://${name}:22000" "dynamic"];
      })
      peers;
      folders.notes = {
        path = notes;
        devices = lib.attrNames peers;
        # Sends edits a second after saving instead of the default ten.
        fsWatcherDelayS = 1;
      };
      options.urAccepted = -1;
    };
  };
  systemd.tmpfiles.settings.syncthing = {
    # Owned by grey, as tmpfiles would otherwise create the folder as root for the file below.
    ${notes}.d = {
      user = "grey";
      group = "users";
      mode = "0700";
    };
    # Ignore patterns stay per device, so Obsidian keeps its settings on the phone.
    "${notes}/.stignore".f = {
      user = "grey";
      group = "users";
      mode = "0644";
      argument = ".obsidian";
    };
  };
}
