{
  config,
  inputs,
  ...
}: let
  mkAlmaSystemConfig = {
    uid,
    gid,
    primaryGroup,
  }:
    inputs.system-manager.lib.makeSystemConfig {
      overlays = [
        inputs.niri.overlays.default
        inputs.niri-screenshare.overlays.default
      ];
      specialArgs = {
        inherit gid inputs primaryGroup uid;
      };
      modules = [
        ({pkgs, ...}: {
          environment.variables = {
            EDITOR = "hx";
            VISUAL = "hx";
          };
          environment.systemPackages = [
            pkgs.gh
            pkgs.curl
            pkgs.wget
            pkgs.fd
            pkgs.ripgrep
            pkgs.microfetch
            pkgs.zoxide
            inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-db
            inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.comma-with-db
            (config.flake.wrappers.bat.wrap {inherit pkgs;})
            (config.flake.wrappers.tlrc.wrap {inherit pkgs;})
            (config.flake.wrappers.lazygit.wrap {inherit pkgs;})
            (config.flake.wrappers.openssh.wrap {inherit pkgs;})
            (config.flake.wrappers.monstar.wrap {inherit pkgs;})
            (config.flake.wrappers.codex.wrap {inherit pkgs;})
            (config.flake.wrappers.helium.wrap {inherit pkgs;})
            (config.flake.wrappers.kitty.wrap {
              inherit pkgs;
              settings.symbol_map =
                "U+e000-U+e00a,U+e0a0-U+e0a2,U+e0a3,U+e0b0-U+e0b3,"
                + "U+e0b4-U+e0c8,U+e0ca,U+e0cc-U+e0d7,U+e200-U+e2a9,"
                + "U+e300-U+e3e3,U+e5fa-U+e6b7,U+e700-U+e8ef,U+ea60-U+ec1e,"
                + "U+ed00-U+efce,U+f000-U+f2ff,U+f300-U+f381,U+f400-U+f533,"
                + "U+f0001-U+f1af0 Symbols Nerd Font Mono";
            })
            (config.flake.wrappers.starship.wrap {inherit pkgs;})
            (config.flake.wrappers.git.wrap {inherit pkgs;})
            (config.flake.wrappers.delta.wrap {inherit pkgs;})
            (config.flake.wrappers.mpv.wrap {inherit pkgs;})
            inputs.mpv-smartcut.packages.${pkgs.stdenv.hostPlatform.system}.default
            (config.flake.wrappers.helix.wrap {
              inherit pkgs;
              nixconfSystem = "systemConfigs.alma";
            })
            (config.flake.wrappers.yazi.wrap {
              inherit pkgs;
            })
            (config.flake.wrappers.bottom.wrap {
              inherit pkgs;
              diskRatio = 2;
              settings.disk.mount_filter.is_list_ignored = inputs.nixpkgs.lib.mkForce true;
            })
          ];
        })
        ./_modules/session.nix
        ./_modules/host.nix
      ];
    };
in {
  perSystem = {system, ...}: {
    packages.system-manager = inputs.system-manager.packages.${system}.default;
  };

  flake = {
    lib.mkAlmaSystemConfig = mkAlmaSystemConfig;
    # Keep a pure, stable output for checks and cache builds. The installer and
    # alma-rebuild call mkAlmaSystemConfig with the native account IDs.
    systemConfigs.alma = mkAlmaSystemConfig {
      uid = 1000;
      gid = 1000;
      primaryGroup = "grey";
    };
  };
}
