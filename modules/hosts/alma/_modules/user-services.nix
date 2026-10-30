{
  lib,
  nixos,
  pkgs,
  ...
}: let
  # Keep Alma's native session infrastructure and the services adapted locally.
  excluded = [
    "dbus-broker.service"
    "dbus.service"
    "dbus.socket"
    "filter-chain.service"
    "niri-screenshare.service"
    "nixos-activation.service"
    "nixos-fake-graphical-session.target"
    "pipewire-pulse.service"
    "pipewire-pulse.socket"
    "pipewire.service"
    "pipewire.socket"
    "speech-dispatcher.socket"
    "sunshine.service"
    "systemd-tmpfiles-clean.timer"
    "systemd-tmpfiles-setup.service"
    "wireplumber.service"
    "xdg-autostart-if-no-desktop-manager.target"
  ];
  units = lib.filterAttrs (name: unit: unit.enable && !(builtins.elem name excluded)) nixos.systemd.user.units;
  baseUnits = lib.filterAttrs (_: unit: unit.overrideStrategy != "asDropin") units;
  utils = import "${pkgs.path}/nixos/lib/utils.nix" {
    inherit lib pkgs;
    config = nixos;
  };
  generated = utils.systemdUtils.lib.generateUnits {
    type = "user";
    inherit units;
    upstreamUnits = [];
    upstreamWants = [];
  };
  # Copy only selected units so native services stay out of Alma's closure.
  source = pkgs.runCommand "alma-user-units" {} (lib.concatStrings (lib.mapAttrsToList (name: unit: ''
    mkdir -p "$out/${name}.d"
    ${lib.optionalString (unit.overrideStrategy != "asDropin") ''
      cp -L ${generated}/${name} "$out/${name}"
    ''}
    touch "$out/${name}.d/overrides.conf"
    for dropin in ${generated}/${name}.d/*.conf; do
      if [[ -f "$dropin" ]]; then
        cat "$dropin" >> "$out/${name}.d/overrides.conf"
        echo >> "$out/${name}.d/overrides.conf"
      fi
    done
  '') units));
  file = source: {
    inherit source;
    mode = "0644";
    replaceExisting = true;
  };
  dependencies = field: directive:
    lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (name: unit:
      map (target:
        lib.nameValuePair "systemd/user/${target}.d/nixconf-${name}-${field}.conf" {
          text = "[Unit]\n${directive}=${name}\n";
          mode = "0644";
          replaceExisting = true;
        }) unit.${field}) units));
in {
  environment.etc =
    lib.mapAttrs' (name: _: lib.nameValuePair "systemd/user/${name}" (file "${source}/${name}")) baseUnits
    // lib.mapAttrs' (name: _:
      lib.nameValuePair "systemd/user/${name}.d/overrides.conf" (file "${source}/${name}.d/overrides.conf")) units
    // lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (name: unit:
      map (alias: lib.nameValuePair "systemd/user/${alias}" {
        source = "${source}/${name}";
        replaceExisting = true;
      }) unit.aliases) units))
    // dependencies "wantedBy" "Wants"
    // dependencies "requiredBy" "Requires"
    // dependencies "upheldBy" "Upholds";
}
