{
  flake.homeModules.nix-language = {config, osConfig, pkgs, ...}: let
    formatProjects = ["nixconf" "helium-flake"];
    formatProjectPatterns = builtins.concatStringsSep "|" (
      map (project: "${config.home.homeDirectory}/${project}/*") formatProjects
    );
    hostName = osConfig.networking.hostName;
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
    home.packages = [nix-format];

    programs.helix.languages = {
      language-server.nixd.command = "${pkgs.nixd}/bin/nixd";
      language-server.nixd.config.options.nixos.expr = "(builtins.getFlake \"path:${config.home.homeDirectory}/nixconf\")"
      + ".nixosConfigurations.${hostName}.options";
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${nix-format}/bin/nix-format";
          language-servers = ["nixd"];
        }
      ];
    };
  };
}
