_: {
  flake.nixosModules.nix-language = _: {
    home-manager.users.grey = {pkgs, ...}: let
      alejandra-patched = pkgs.alejandra.overrideAttrs (prev: {
        patches = (prev.patches or []) ++ [./alejandra.patch];
        doCheck = false;
      });

      nix-format = pkgs.writeShellApplication {
        name = "nix-format";
        runtimeInputs = with pkgs; [
          alejandra-patched
          deadnix
          statix
        ];
        text = ''
          file=$(mktemp --suffix=.nix)
          trap 'rm -f "$file"' EXIT
          cat > "$file"
          deadnix --edit -q "$file" >/dev/null 2>&1
          statix fix "$file" >/dev/null 2>&1
          alejandra -q "$file" >/dev/null
          cat "$file"
        '';
      };
    in {
      home.packages = with pkgs; [
        nix-format
        nixd
      ];

      programs = {
        helix.languages.language-server.nixd.config.options.nixos.expr =
          "(builtins.getFlake \"path:/home/grey/nixconf\")" + ".nixosConfigurations.desktop.options";

        zed-editor.userSettings.lsp.nixd.initialization_options.nixos.expr =
          "(builtins.getFlake \"path:/home/grey/nixconf\")" + ".nixosConfigurations.desktop.options";
      };
    };
  };
}
