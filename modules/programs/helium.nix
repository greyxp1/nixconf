{inputs, ...}: {
  flake.nixosModules.helium = {config, ...}: {
    imports = [inputs.helium.nixosModules.helium inputs.self.nixosModules.discord-browser];
    programs.helium = {
      enable = true;
      defaultBrowser = true;

      flags = [
        "--enable-features=HeliumMiddleClickAutoscroll"
        "--disable-features=MiddleClickPasteEnabled"
      ];

      extraPolicies = {
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "Google";
        DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?output=chrome&q={searchTerms}";
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
        equicord.path = config.programs.nixcord.browser.finalPackage;
        sponsorBlock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";
        deArrow.id = "enamippconapkdmgfgjchkhakpfinmaj";
        controlPanel.id = "lodcanccmfbpjjpnngindkkmiehimile";
        alternatePlayer.id = "aojjiodaaogdbbcnbpjnojilccopgcbk;https://edge.microsoft.com/extensionwebstorebase/v1/crx";

        ublock = {
          id = "blockjmkbacgjkknlgpkjjiijinjdanf";
          install = false;
          pin = true;
        };

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
  };
}
