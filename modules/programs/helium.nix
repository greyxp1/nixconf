{inputs, ...}: {
  flake.nixosModules.helium = {...}: {
    imports = [inputs.helium.nixosModules.helium];
    home-manager.users.grey = _: {
      programs.helium = {
        enable = true;
        defaultBrowser = true;

        flags = [
          "--ozone-platform-hint=auto"
          "--enable-features=HeliumMiddleClickAutoscroll"
        ];

        extensions = {
          sponsorBlock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";
          deArrow.id = "enamippconapkdmgfgjchkhakpfinmaj";
          controlPanel.id = "lodcanccmfbpjjpnngindkkmiehimile";
          claudeUsageTracker.id = "knemcdpkggnbhpoaaagmjiigenifejfo";
          claudeQoL.id = "dkdnancajokhfclpjpplkhlkbhaeejob";
          betterLyrics.id = "effdbpeggelllpfkjppbokhmmiinhlmg";
          equicord.id = "mcambpfmpjnncfoodejdmehedbkjepmi";

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
          browser.show_forward_button = false;
          helium.browser = {
            layout = 2;
            show_avatar_button = false;
            show_back_button = false;
            show_reload_button = false;
            show_vertical_tabs_collapse_button = false;
            zen_mode = true;
            zen_mode_sidebar_pinned = true;
            zen_mode_top_chrome_pinned = true;
          };
          #bookmark_bar = {
          #  show_apps_shortcut = false;
          #  show_managed_bookmarks = false;
          #  show_on_all_tabs = false;
          #  show_tab_groups = false;
          #};
        };
      };
    };
  };
}
