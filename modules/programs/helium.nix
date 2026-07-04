{inputs, ...}: {
  flake.nixosModules.helium = {imports = [inputs.helium.nixosModules.helium];};
  flake.homeModules.helium = {
    programs.helium = {
      enable = true;
      defaultBrowser = true;
      flags = ["--enable-features=HeliumMiddleClickAutoscroll"];

      extraPolicies = {
        RestoreOnStartup = 1;
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "Google";
        DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?output=chrome&q={searchTerms}";
      };

      extensions = {
        sponsorBlock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";
        deArrow.id = "enamippconapkdmgfgjchkhakpfinmaj";
        controlPanel.id = "lodcanccmfbpjjpnngindkkmiehimile";
        betterLyrics.id = "effdbpegglllpfkjppbokhmmiinhlmg";
        equicord.id = "mcambpfmpjnncfoodejdmehedbkjepmi";
        re-start.id = "fdodcmjeojbmcgmhcgcelffcekhicnop";
        protonPass.id = "ghmbeldphafepmbegfdlkpapadhbakde";
        protonPass.pin = true;
        raindrop.id = "ldgfbffkinooeloadekpmfoklnobpien";
        raindrop.pin = true;
        pipView.id = "eaeedemddlledlghhjebjgdmhjekgegd";
        pipView.pin = true;
      };

      preferences = {
        ntp.shortcust_visible = false;
        auto_pin_new_tab_groups = false;
        bookmark_bar.show_tab_groups = false;

        helium.browser = {
          layout = 2;
          mru_tab_cycling = true;
          show_avatar_button = false;
          show_back_button = false;
          show_reload_button = false;
          rounded_frame = false;
          show_vertical_tabs_collapse_button = false;
        };

        browser = {
          show_forward_button = false;
          custom_chrome_frame = false;
        };
      };
    };
  };
}
