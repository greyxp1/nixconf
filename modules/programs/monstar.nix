{inputs, ...}: {
  flake.nixosModules.monstar = {pkgs, ...}: {
    imports = [./_nixos-modules/monstar.nix];
    programs.monstar.enable = true;
    fonts.packages = [pkgs.jetbrains-mono pkgs.nerd-fonts.symbols-only];
    programs.monstar.package = inputs.monstar.packages.${pkgs.stdenv.hostPlatform.system}.default;
    programs.monstar.settings = {
      font-family = "JetBrains Mono";
      font-size = 14;
      background-opacity = 0.8;
      window-padding-x = 8;
      window-padding-y = 8;
      selection-background = "#0078D7";
      theme = pkgs.runCommand "monstar-catppuccin-mocha" {} ''
        sed '/^split-divider-color =/d' \
          ${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.ghostty}/catppuccin-mocha.conf > "$out"
      '';
    };
  };
}
