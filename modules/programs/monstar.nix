{inputs, ...}: {
  flake.nixosModules.monstar = {pkgs, ...}: {
    imports = [inputs.self.wrappers.monstar.install];
    wrappers.monstar.enable = true;
    fonts.packages = [pkgs.jetbrains-mono pkgs.nerd-fonts.symbols-only];
  };
  flake.wrappers.monstar = {pkgs, ...}: {
    imports = ["${inputs.wrapper-monstar}/wrapperModules/m/monstar/module.nix"];
    package = inputs.monstar.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
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
