{
  inputs,
  lib,
  pkgs,
  ...
}: let
  swapOutputs = pkgs.writeShellApplication {
    name = "niri-swap-outputs";
    runtimeInputs = [pkgs.jq];
    text = ''
      outputs=$(niri msg --json outputs)
      mapfile -t active_outputs < <(
        jq -r '
          [to_entries[] | select(.value.logical != null)]
          | sort_by(.value.logical.x)
          | .[]
          | [
              .value.name,
              .value.logical.x,
              .value.logical.y,
              .value.logical.width
            ]
          | @tsv
        ' <<< "$outputs"
      )

      if (( ''${#active_outputs[@]} != 2 )); then
        echo "Expected exactly two active outputs." >&2
        exit 1
      fi

      IFS=$'\t' read -r left_output left_x left_y left_width <<< "''${active_outputs[0]}"
      IFS=$'\t' read -r right_output right_x right_y right_width <<< "''${active_outputs[1]}"
      output_gap=$((right_x - left_x - left_width))
      temporary_x=$((right_x + right_width))

      niri msg output "$left_output" position set "$temporary_x" "$left_y"
      niri msg output "$right_output" position set "$left_x" "$left_y"
      niri msg output "$left_output" position set "$((left_x + right_width + output_gap))" "$right_y"
    '';
  };
  almaNiri = inputs.self.wrappers.niri.wrap {
    inherit pkgs;
    settings.binds = {
      "Mod+E" = lib.mkForce (_: {
        props.repeat = false;
        content.spawn = ["monstar" "-e" "yazi"];
      });
      "Mod+Shift+O" = _: {
        props.repeat = false;
        content.spawn = "niri-swap-outputs";
      };
    };
  };
  wrappers = inputs.self.wrappers;
  termfilechooser = wrappers.termfilechooser.wrap {inherit pkgs;};
  screenshots = pkgs.niri-screenshare.override {withPicker = false;};
  sessionService = command: {
    Unit = {
      After = "graphical-session.target";
      PartOf = "graphical-session.target";
    };
    Service = {
      ExecStart = command;
      Restart = "on-failure";
    };
    Install.WantedBy = "graphical-session.target";
  };
  services = {
    vellum = lib.recursiveUpdate (sessionService "${inputs.vellum.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/vellum") {
      Service.Environment = "LD_LIBRARY_PATH=${lib.makeLibraryPath [pkgs.vulkan-loader]}";
    };
    perch = sessionService "${inputs.perch.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/perch --daemon";
    xdg-desktop-portal = {
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.portal.Desktop";
        ExecStart = "${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal";
      };
    };
    xdg-desktop-portal-gtk = {
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.gtk";
        ExecStart = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
      };
    };
    xdg-desktop-portal-termfilechooser = {
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.termfilechooser";
        ExecStart = "${termfilechooser}/libexec/xdg-desktop-portal-termfilechooser";
      };
    };
    niri-screenshare = lib.recursiveUpdate (sessionService "${screenshots}/bin/niri-screenshare") {
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.niri";
        Environment = "NIRI_SCREENSHARE_NO_PORTAL_CONFIG=1";
      };
    };
  };
in {
  imports = [
    (import ./_userServices.nix services)
  ];
  environment.etc = {
    "systemd/user/niri.service" = {
      source = "${almaNiri}/share/systemd/user/niri.service";
      mode = "0644";
      replaceExisting = true;
    };
    "systemd/user/niri-shutdown.target" = {
      source = "${almaNiri}/share/systemd/user/niri-shutdown.target";
      mode = "0644";
      replaceExisting = true;
    };
    "xdg/xdg-desktop-portal/niri-portals.conf".text = ''
      [preferred]
      default=gtk
      org.freedesktop.impl.portal.FileChooser=termfilechooser
      org.freedesktop.impl.portal.ScreenCast=niri
      org.freedesktop.impl.portal.Secret=none
    '';
    "fonts/conf.d/99-nixconf.conf".text = ''
      <?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig><dir>/run/system-manager/sw/share/fonts</dir></fontconfig>
    '';
  };
  environment.variables = {
    XDG_DATA_DIRS = "/run/system-manager/sw/share:/usr/local/share:/usr/share";
    XDG_CONFIG_DIRS = "/etc/xdg";
  };
  environment.pathsToLink = ["/share/fonts" "/share/icons" "/share/terminfo" "/share/dbus-1" "/share/xdg-desktop-portal"];
  environment.systemPackages = [
    swapOutputs
    almaNiri
    termfilechooser
    screenshots
    inputs.perch.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.xdg-desktop-portal
    pkgs.xdg-desktop-portal-gtk
    pkgs.xwayland-satellite
    pkgs.wl-clipboard
    (pkgs.tesseract.override {enableLanguages = ["eng"];})
  ];
}
