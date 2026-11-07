{inputs, lib, pkgs, ...}: {
  imports = [inputs.relay.nixosModules.default];

  services.relay.enable = true;
  programs.nixcord = {
    userPlugins."relay.browser" = inputs.relay.packages.${pkgs.stdenv.hostPlatform.system}.plugin;
    browser.extraConfig.plugins = {
      Relay = {
        enabled = true;
        autoShare = true;
      };
      InstantScreenshare.enabled = false;
      LimitlessScreenshare.enabled = false;
      WebScreenShare.enabled = false;
      WebScreenShareFixes.enabled = lib.mkForce false;
      FakeNitro.enableStreamQualityBypass = false;
    };
  };
}
