{inputs, ...}: {
  flake.nixosModules.helium = {imports = [inputs.helium.nixosModules.helium];};
  flake.homeModules.helium = {
    programs.helium = {
      enable = true;
      defaultBrowser = true;
      flags = ["--enable-features=HeliumMiddleClickAutoscroll"];

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
          vertical_right_aligned = true;
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
        re-start.id = "fdodcmjeojbmcgmhcgcelffcekhicnop";

        ublock = {
          id = "blockjmkbacgjkknlgpkjjiijinjdanf";
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

        pipView = {
          id = "eaeedemddlledlghhjebjgdmhjekgegd";
          pin = true;
        };
      };
    };
  };
}
