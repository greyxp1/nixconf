{
  config,
  lib,
  pkgs,
  ...
}: let
  serviceManifest = pkgs.writeText "alma-native-services" (
    lib.concatStringsSep "\n" config.alma.services + "\n"
  );
in {
  alma.activation.services = ''
    previous_services="$state_dir/native-services"
    /usr/bin/hostnamectl set-hostname ${lib.escapeShellArg config.alma.hostName}
    /usr/bin/timedatectl set-timezone ${lib.escapeShellArg config.alma.timeZone}
    /usr/bin/systemctl set-default ${lib.escapeShellArg config.alma.defaultTarget}
    /usr/bin/systemctl daemon-reload

    if [[ -f $previous_services ]]; then
      while IFS= read -r service; do
        [[ -z $service ]] && continue
        if ! ${pkgs.gnugrep}/bin/grep -Fxq "$service" ${serviceManifest}; then
          /usr/bin/systemctl disable --now "$service"
        fi
      done < "$previous_services"
    fi
    while IFS= read -r service; do
      [[ -z $service ]] || /usr/bin/systemctl enable --now "$service"
    done < ${serviceManifest}
    /usr/bin/install -m 0644 ${serviceManifest} "$previous_services.new"
    /usr/bin/mv -f "$previous_services.new" "$previous_services"
  '';
}
