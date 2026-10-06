{
  almaNiri,
  gid,
  inputs,
  primaryGroup,
  uid,
  lib,
  pkgs,
  ...
}: let
  systemManager = inputs.system-manager.packages.${pkgs.stdenv.hostPlatform.system}.default;
  alma-rebuild = pkgs.writeShellScriptBin "alma-rebuild" ''
    set -euo pipefail
    umask 022
    export PATH=/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

    cd /home/grey/Projects/nixconf
    unset NIX_PATH
    system_config=$(
      NIXCONF_UID=${lib.escapeShellArg (toString uid)} \
      NIXCONF_GID=${lib.escapeShellArg (toString gid)} \
      NIXCONF_PRIMARY_GROUP=${lib.escapeShellArg primaryGroup} \
      nix build --impure --no-link --print-out-paths \
        --file /home/grey/Projects/nixconf/modules/system/hosts/alma/_build.nix
    )
    ${systemManager}/bin/system-manager register --store-path "$system_config" --sudo
    ${systemManager}/bin/system-manager activate --store-path "$system_config" --sudo
    [[ ! -L result ]] || /usr/bin/rm -f result
    sudo /usr/bin/systemctl restart alma-host.service
  '';
  wrappers = inputs.self.wrappers;
  noctalia = wrappers.noctalia.wrap {
    inherit pkgs;
    settings = {
      bar.default.margin_ends = lib.mkForce 415;
      plugin_settings."noctalia/screen_recorder".video_codec = lib.mkForce "h264";
    };
  };
  termfilechooser = wrappers.termfilechooser.wrap {inherit pkgs;};
  screenshots = (pkgs.niri-screenshare.override {withPicker = false;}).overrideAttrs {
    cargoBuildNoDefaultFeatures = true;
    cargoCheckNoDefaultFeatures = true;
  };
  sunshine = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux.sunshine.overrideAttrs (old: {
    patches = (old.patches or []) ++ [../../../../programs/remote/sunshine-keyboard.patch];
  });
  hostSunshine = pkgs.replaceDirectDependencies {
    drv = sunshine;
    replacements = [
      {
        oldDependency = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux.glibc;
        newDependency = pkgs.glibc;
      }
    ];
  };
  display = pkgs.writeShellApplication {
    name = "sunshine-display";
    runtimeInputs = [pkgs.niri pkgs.jq];
    text = builtins.readFile ../../../../programs/remote/sunshine-display.sh;
  };
  prepCommands = builtins.toJSON [
    {
      do = "${lib.getExe display} start";
      undo = "${lib.getExe display} restore";
    }
  ];
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
    noctalia = sessionService "${noctalia}/bin/noctalia";
    vellum = lib.recursiveUpdate (sessionService "${inputs.vellum.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/vellum") {
      Service.Environment = "LD_LIBRARY_PATH=${lib.makeLibraryPath [pkgs.vulkan-loader]}";
    };
    perch = sessionService "${inputs.perch.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/perch --daemon";
    ssh-agent = {
      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/ssh-agent";
        ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent";
        Restart = "on-failure";
      };
      Install.WantedBy = "default.target";
    };
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
      };
    };
    "app-dev.lizardbyte.app.Sunshine" = lib.recursiveUpdate (sessionService (lib.escapeShellArgs [
      "${hostSunshine}/bin/sunshine"
      "hevc_mode=1"
      "csrf_allowed_origins=https://alma.tail1785c.ts.net:47990"
      "vaapi_quality=balanced"
      "qp=20"
      "global_prep_cmd=${prepCommands}"
    ])) {Service.ExecStopPost = "-${lib.getExe display} restore";};
  };
  userUnits = lib.mapAttrs' (name: unit:
    lib.nameValuePair "systemd/user/${name}.service" {
      text = lib.generators.toINI {} unit;
      mode = "0644";
      replaceExisting = true;
    })
  services;
  enabledUnits = lib.mapAttrs' (target: names:
    lib.nameValuePair "systemd/user/${target}.d/nixconf.conf" {
      text = "[Unit]\nWants=${lib.concatMapStringsSep " " (name: "${name}.service") names}\n";
      mode = "0644";
      replaceExisting = true;
    }) (lib.groupBy (name: services.${name}.Install.WantedBy)
    (builtins.attrNames (lib.filterAttrs (_: unit: unit ? Install.WantedBy) services)));

in {
  imports = [
    inputs.self.nixosModules.scrcpy
    inputs.self.remoteClientModule
    ./niri.nix
    (import ./shell.nix {inherit inputs;})
  ];
  environment.etc =
    userUnits
    // enabledUnits
    // {
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
      "xdg/mimeapps.list".text = ''
        [Default Applications]
        text/html=helium.desktop
        x-scheme-handler/http=helium.desktop
        x-scheme-handler/https=helium.desktop
        inode/directory=yazi.desktop
      '';
      "fonts/conf.d/99-nixconf.conf".text = ''
        <?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig><dir>/run/system-manager/sw/share/fonts</dir></fontconfig>
      '';
      "xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=catppuccin-mocha-mauve-standard
        gtk-application-prefer-dark-theme=1
        gtk-cursor-theme-name=catppuccin-mocha-mauve-cursors
        gtk-cursor-theme-size=24
      '';
    };
  environment.variables = {
    XDG_DATA_DIRS = "/run/system-manager/sw/share:/usr/local/share:/usr/share";
    XDG_CONFIG_DIRS = "/etc/xdg";
    XCURSOR_THEME = "catppuccin-mocha-mauve-cursors";
    XCURSOR_SIZE = "24";
  };
  environment.pathsToLink = ["/share/fonts" "/share/icons" "/share/terminfo" "/share/dbus-1" "/share/xdg-desktop-portal"];
  environment.systemPackages = [
    almaNiri
    noctalia
    termfilechooser
    screenshots
    hostSunshine
    pkgs.xdg-desktop-portal
    pkgs.xdg-desktop-portal-gtk
    pkgs.gpu-screen-recorder
    pkgs.xwayland-satellite
    pkgs.wl-clipboard
    (pkgs.tesseract.override {enableLanguages = ["eng"];})
    pkgs.catppuccin-cursors.mochaMauve
    (pkgs.catppuccin-gtk.override {
      accents = ["mauve"];
      variant = "mocha";
    })

    alma-rebuild
    inputs.ncr.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
    pkgs.tack
  ];
}
