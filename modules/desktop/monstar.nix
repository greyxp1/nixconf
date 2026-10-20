{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [../_custom-modules/monstar.nix];
  programs.monstar.enable = true;
  fonts.packages = [pkgs.jetbrains-mono pkgs.nerd-fonts.symbols-only];
  # Monstar's Ghostty dependency requires Zig 0.16.
  programs.monstar.package =
    (inputs.monstar.packages.${pkgs.stdenv.hostPlatform.system}.default).overrideAttrs (old: {
      nativeBuildInputs =
        map (
          input:
            if lib.isDerivation input && input.drvPath == pkgs.zig.drvPath
            then pkgs.zig_0_16
            else input
        )
        old.nativeBuildInputs;
    });
  programs.monstar.settings = {
    font-family = "JetBrains Mono";
    font-size = 14;
    background-opacity = 0.8;
    window-padding-x = 8;
    window-padding-y = 8;
    notify-on-command-finish = "unfocused";
    notify-on-command-finish-action = "no-bell,notify";
    selection-background = "#0078D7";
    theme = pkgs.runCommand "monstar-catppuccin-mocha" {} ''
      sed '/^split-divider-color =/d' \
        ${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.ghostty}/catppuccin-mocha.conf > "$out"
    '';
  };
}
