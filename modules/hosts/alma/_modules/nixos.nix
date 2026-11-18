{
  inputs,
  lib,
  pkgs,
  uid,
  ...
}: let
  base = inputs.nixpkgs.lib.nixosSystem {
    inherit pkgs;
    specialArgs = {inherit inputs;};
    modules = [
      inputs.preservation.nixosModules.preservation
      {
        system.stateVersion = "26.11";
        networking.hostName = "alma";
        users.users.grey = {
          inherit uid;
          isNormalUser = true;
        };
        xdg.mime.defaultApplications."inode/directory" = "yazi.desktop";
      }
    ];
  };
  extended = base.extendModules {
    modules = [
      # Alma selects shared modules here, independently of the NixOS layout.
      ../../../core/bottom.nix
      ../../../core/cli.nix
      ../../../core/git.nix
      ../../../core/helix.nix
      ../../../core/fish.nix
      ../../../core/rex.nix
      ../../../core/ssh.nix
      ../../../core/yazi.nix
      ../../../graphical/helium.nix
      ../../../graphical/monstar.nix
      ../../../graphical/mpv.nix
      ../../../graphical/niri.nix
      ../../../graphical/noctalia/noctalia.nix
      ../../../graphical/wallpaper.nix
      ../../../graphical/remote-client.nix
      ../../../graphical/scrcpy.nix
      ../../../graphical/sunshine.nix
      ../../../core/secrets.nix
      ../../../core/syncthing.nix
      ../../../core/t3code.nix
      ../../../graphical/termfilechooser.nix
      ../../../graphical/theme.nix
      ({config, ...}: let
        resizeDisk = widget: widget // lib.optionalAttrs ((widget.type or "") == "disk") {ratio = 2;} // lib.optionalAttrs (widget ? child) {child = map resizeDisk widget.child;};
      in {
        options.programs.bottom.settings = lib.mkOption {
          apply = settings:
            lib.recursiveUpdate settings {
              row = map resizeDisk settings.row;
              disk.mount_filter.is_list_ignored = true;
            };
        };
        config = {
          # system-manager cannot run nix-secrets, so Alma keeps its secrets by hand.
          security.nix-secrets.enable = lib.mkForce false;
          programs.claude-code.settings.apiKeyHelper = lib.mkForce "cat /home/grey/.config/cliproxyapi/client-key";
          programs.codex.settings.model_providers.cliproxy.auth.args = lib.mkForce ["/home/grey/.config/cliproxyapi/client-key"];
          # Alma's systemd does not support this newer slice setting.
          systemd.user.slices.app-t3code.sliceConfig.ManagedOOMMemoryPressureDurationSec = lib.mkForce [];
          # The school network blocks QUIC.
          programs.t3code.server.connect.protocol = "http2";
          systemd.user.services.t3code.environment.NIX_SSL_CERT_FILE = "/etc/pki/tls/certs/ca-bundle.crt";
          programs.niri.settings.binds = {
            "Mod+Shift+O" = {
              action.spawn = "niri-swap-outputs";
            };
          };
          programs.noctalia.settings = {
            bar.default.margin_ends = lib.mkForce 415;
            plugin_settings."noctalia/screen_recorder".video_codec = lib.mkForce "h264";
          };
          programs.helix.languages.language-server.nixd.config = {
            nixpkgs.expr = "import ${pkgs.path} {}";
            options.nixos.expr =
              lib.mkForce "(builtins.getFlake \"path:${config.programs.nh.flake}\").systemConfigs.alma.options";
          };
        };
      })
    ];
  };
  nixos = extended.config;
  baseSources = map (definition: definition.file) base.options.environment.systemPackages.definitionsWithLocations;
  packages = lib.concatMap (definition: definition.value) (builtins.filter
    (definition: !(builtins.elem definition.file baseSources))
    extended.options.environment.systemPackages.definitionsWithLocations);
in {
  _module.args.nixos = nixos;
  # Install program additions without replacing Alma's native system tools.
  environment.systemPackages = builtins.filter (package: toString package != toString nixos.services.sunshine.package) packages;
}
