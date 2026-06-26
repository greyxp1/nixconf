{inputs, ...}: {
  flake.nixosModules.helium = {...}: {
    imports = [inputs.helium.nixosModules.helium];
    home-manager.users.grey = _: {
      programs.helium = {
        enable = true;
        defaultBrowser = true;
        extraPolicies.RestoreOnStartup = 1;
        flags = ["--enable-features=HeliumMiddleClickAutoscroll"];

        extensions = {
          sponsorBlock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";
          deArrow.id = "enamippconapkdmgfgjchkhakpfinmaj";
          controlPanel.id = "lodcanccmfbpjjpnngindkkmiehimile";
          claudeUsageTracker.id = "knemcdpkggnbhpoaaagmjiigenifejfo";
          claudeQoL.id = "dkdnancajokhfclpjpplkhlkbhaeejob";
          betterLyrics.id = "effdbpeggelllpfkjppbokhmmiinhlmg";
          equicord.id = "mcambpfmpjnncfoodejdmehedbkjepmi";
          re-start.id = "fdodcmjeojbmcgmhcgcelffcekhicnop";

          protonPass.id = "ghmbeldphafepmbegfdlkpapadhbakde";
          protonPass.pin = true;

          raindrop.id = "ldgfbffkinooeloadekpmfoklnobpien";
          raindrop.pin = true;

          pipView.id = "eaeedemddlledlghhjebjgdmhjekgegd";
          pipView.pin = true;

          darkReader.id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
          darkReader.pin = true;
        };

        preferences = {
          ntp.shortcust_visible = false;
          auto_pin_new_tab_groups = false;
          bookmark_bar.show_tab_groups = false;

          helium.browser = {
            layout = 2;
            centered_location_bar = true;
            mru_tab_cycling = true;
            show_avatar_button = false;
            show_back_button = false;
            show_reload_button = false;
            rounded_frame = false;
            show_vertical_tabs_collapse_button = false;
            zen_mode = true;
            zen_mode_sidebar_pinned = true;
            zen_mode_top_chrome_pinned = true;
          };

          browser = {
            show_forward_button = false;
            custom_chrome_frame = false;
          };
        };
      };
    };
  };
}
