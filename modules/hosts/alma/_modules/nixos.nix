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
        programs.ydotool.group = lib.mkForce "input";
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
      ../../../core/nushell.nix
      ../../../core/ssh.nix
      ../../../core/yazi.nix
      ../../../desktop/helium.nix
      ../../../desktop/monstar.nix
      ../../../desktop/mpv.nix
      ../../../desktop/niri.nix
      ../../../desktop/noctalia/noctalia.nix
      ../../../desktop/remote-client.nix
      ../../../desktop/scrcpy.nix
      ../../../desktop/sunshine.nix
      ../../../desktop/t3code.nix
      ../../../desktop/termfilechooser.nix
      ../../../desktop/theme.nix
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
          programs.nixcord.discord.enable = lib.mkForce false;
          programs.inshellah.extraDirs = ["/run/system-manager/sw/share/inshellah"];
          programs.niri.settings.binds = {
            "Mod+E" = lib.mkForce {
              repeat = false;
              action.spawn = ["monstar" "-e" "yazi"];
            };
            "Mod+Shift+O" = {
              repeat = false;
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
