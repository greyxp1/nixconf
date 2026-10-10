{
  inputs,
  lib,
  ...
}: {
  flake.nixosModules.remote-client = {
    config,
    pkgs,
    ...
  }: let
    client = pkgs.moonlight-embedded.overrideAttrs (old: {
      src = inputs.moonlight-embedded;
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace src/sdl.c \
            --replace-fail 'SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC' 'SDL_RENDERER_ACCELERATED'
        '';
    });
    connect = pkgs.writeShellApplication {
      name = "remote-connect";
      runtimeInputs = [client pkgs.niri pkgs.jq];
      text = ''
        monitor=$(niri msg --json focused-output)
        read -r width height fps < <(
          jq -er '
            .modes[.current_mode]
            | [.width, .height, (.refresh_rate / 1000 | round)] | @tsv
          ' <<< "$monitor"
        )

        echo "Requesting ''${width}x''${height} at ''${fps} FPS."
        export SDL_VIDEODRIVER=wayland
        exec moonlight stream "''${1:?Expected host}" -app Desktop -quitappafter -platform sdl \
          -width "$width" -height "$height" -fps "$fps" \
          -bitrate "''${2:?Expected bitrate}" -packetsize 1024 -codec h264 \
          -keydir "''${3:?Expected key directory}"
      '';
    };
    keyDirectory = "/home/grey/.local/share/moonlight";
    stream = address: bitrate: "${lib.getExe connect} ${address} ${toString bitrate} ${keyDirectory}";
  in {
    environment.systemPackages =
      [client]
      ++ lib.mapAttrsToList (name: address:
        pkgs.makeDesktopItem {
          name = "remote-${name}";
          desktopName = "Connect to ${lib.toSentenceCase name}";
          comment = "Remote desktop over Tailscale";
          icon = "${pkgs.adwaita-icon-theme-legacy}/share/icons/AdwaitaLegacy/48x48/places/network-workgroup.png";
          exec = stream address 6000;
          terminal = false;
          categories = ["Network" "RemoteAccess"];
          actions =
            {
              pair = {
                name = "Pair";
                exec = "monstar --hold -e moonlight pair ${address} -keydir ${keyDirectory}";
              };
            }
            // lib.optionalAttrs (name == "desktop") {
              high-quality = {
                name = "Connect (high quality, home network)";
                exec = stream address 20000;
              };
            };
        }) (lib.filterAttrs (name: _: name != config.networking.hostName) {
        alma = "alma.tail1785c.ts.net";
        desktop = "desktop.tail1785c.ts.net";
      });
  };
}
