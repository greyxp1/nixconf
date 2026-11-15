{
  config,
  lib,
  ...
}: let
  # Syncthing creates each host's ID on first start. Add it here from a peer's pending devices
  # or `syncthing device-id --home ~/.config/syncthing`, then rebuild every host. A reinstalled
  # host keeps its ID only if ~/.config/syncthing is restored.
  devices = {
    desktop = "SZPGBLD-JSMNNQT-FBKOBQ4-2ZTKES4-CWYCHJP-IAX4KC4-AMB2F3Z-ODYBYQL";
    server = "OAETKIB-GLNECRC-YMOWH6H-J4RMOBQ-NUMUFPK-FDPB47E-3EAUTGX-DSSKCAT";
    laptop = "55HVKIA-5JTEWB7-63HKSBZ-NFWG6AU-2IHWSDB-H5AUQUV-P4CMJ7Q-WSSTLAZ";
    pixel-9 = "O2BEKRC-VAKWYYH-WAW6C2L-WNU37RH-CXOD2GO-JL7OXU2-XDVFJ3A-UMPXNAA";
  };
  host = config.networking.hostName;
  # Every device connects directly to every other, so syncing never waits on one host.
  peers = lib.removeAttrs devices [host];
  notes = "/home/grey/Documents/Notes";
in {
  services.syncthing = {
    enable = true;
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
