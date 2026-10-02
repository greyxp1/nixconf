{inputs, ...}: {
  flake.nixosModules.helium = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.self.wrappers.helium.install];
    wrappers.helium.enable = true;
    environment.sessionVariables.BROWSER = "helium";
    environment.etc =
      lib.genAttrs [
        "chromium/policies/managed/helium.json"
        "helium/policies/managed/helium.json"
      ] (_: {text = builtins.toJSON config.wrappers.helium.policies;})
      // {
        "xdg/mimeapps.list".text = ''
          [Default Applications]
          text/html=helium.desktop
          x-scheme-handler/http=helium.desktop
          x-scheme-handler/https=helium.desktop
        '';
      };
  };
  flake.wrappers.helium = {
    pkgs,
    wlib,
    ...
  }: {
    imports = [wlib.wrapperModules.helium];
    package = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default;

    flags = {
      "--enable-features" = "HeliumMiddleClickAutoscroll";
      "--disable-features" = "MiddleClickPasteEnabled";
    };

    policies = {
      DefaultSearchProviderEnabled = true;
      DefaultSearchProviderName = "Google";
      DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
      DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?output=chrome&q={searchTerms}";
      ExtensionSettings.blockjmkbacgjkknlgpkjjiijinjdanf.toolbar_pin = "force_pinned"; #pin ublock
    };

    preferences = {
      helium.browser = {
        show_back_button = false;
        show_reload_button = false;
        #vertical_right_aligned = true;
        #centered_location_bar = true;
      };

      browser = {
        show_forward_button = false;
        custom_chrome_frame = false;
      };
    };

    extensions = {
      sponsorBlock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";
      deArrow.id = "enamippconapkdmgfgjchkhakpfinmaj";
      controlPanel.id = "lodcanccmfbpjjpnngindkkmiehimile";
      alternatePlayer.id = "aojjiodaaogdbbcnbpjnojilccopgcbk;https://edge.microsoft.com/extensionwebstorebase/v1/crx";

      protonPass = {
        id = "ghmbeldphafepmbegfdlkpapadhbakde";
        pin = true;
      };

      raindrop = {
        id = "ldgfbffkinooeloadekpmfoklnobpien";
        pin = true;
      };
    };
  };
}
