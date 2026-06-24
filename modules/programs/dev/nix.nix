_: {
  flake.nixosModules.nix-language = _: {
    home-manager.users.grey = {config, pkgs, ...}: let
      formatProjects = ["nixconf" "helium-flake"];
      formatProjectPatterns = builtins.concatStringsSep "|" (
        map (project: "${config.home.homeDirectory}/${project}/*") formatProjects
      );
      nixosOptionsExpr = "(builtins.getFlake \"path:/home/grey/nixconf\")"
      + ".nixosConfigurations.desktop.options";
      alejandra = pkgs.alejandra.overrideAttrs (prev: {
        patches = (prev.patches or []) ++ [./alejandra.patch];
        doCheck = false;
      });

      nix-format = pkgs.writeShellApplication {
        name = "nix-format";
        runtimeInputs = with pkgs; [alejandra deadnix statix];
        text = ''
          file=$(mktemp --suffix=.nix)
          trap 'rm -f "$file"' EXIT
          cat > "$file"
          case "$PWD/" in
            ${formatProjectPatterns})
              deadnix --edit -q "$file" >/dev/null 2>&1
              statix fix "$file" >/dev/null 2>&1
              alejandra -q "$file" >/dev/null
              ;;
          esac
          cat "$file"
        '';
      };
    in {
      home.packages = with pkgs; [nix-format nixd];
      programs = {
        helix.languages.language-server.nixd.config.options.nixos.expr = nixosOptionsExpr;
        zed-editor.userSettings.lsp.nixd.initialization_options.nixos.expr = nixosOptionsExpr;
      };
    };
  };
}
