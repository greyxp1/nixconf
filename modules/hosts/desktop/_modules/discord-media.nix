{inputs, pkgs, ...}: {
  imports = [inputs.suncord-bridge.nixosModules.default];

  services.suncord-bridge.enable = true;
  programs.nixcord = {
    userPlugins."suncordBridge.browser" = inputs.suncord-bridge.packages.${pkgs.stdenv.hostPlatform.system}.plugin;
    browser.extraConfig.plugins.SuncordBridge.enabled = true;
  };
}
