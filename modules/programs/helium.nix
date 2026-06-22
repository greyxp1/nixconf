{inputs, ...}: {
  flake.nixosModules.helium = {...}: {
    imports = [inputs.helium.nixosModules.helium];
    home-manager.users.grey = {...}: {
      imports = [inputs.helium.homeModules.helium];
      programs.helium = {
        enable = true;
        defaultBrowser = true;

        extraFlags = [
          "--ozone-platform-hint=auto"
          "--enable-features=HeliumMiddleClickAutoscroll"
        ];

        extraPolicies = {
          ExtensionInstallForcelist = [
            "ghmbeldphafepmbegfdlkpapadhbakde" # Proton Pass
            "ldgfbffkinooeloadekpmfoklnobpien" # Raindrop.io
            "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
            "enamippconapkdmgfgjchkhakpfinmaj" # DeArrow
            "lodcanccmfbpjjpnngindkkmiehimile" # Control Panel for YouTube
            "eaeedemddlledlghhjebjgdmhjekgegd" # PiP View
            "knemcdpkggnbhpoaaagmjiigenifejfo" # Claude Usage Tracker
            "dkdnancajokhfclpjpplkhlkbhaeejob" # Claude QoL
            "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
            "effdbpeggelllpfkjppbokhmmiinhlmg" # Better Lyrics
            "mcambpfmpjnncfoodejdmehedbkjepmi" # Equicord
          ];

          ExtensionSettings = {
            "ghmbeldphafepmbegfdlkpapadhbakde".toolbar_pin = "force_pinned"; # Proton Pass
            "ldgfbffkinooeloadekpmfoklnobpien".toolbar_pin = "force_pinned"; # Raindrop.io
            "eaeedemddlledlghhjebjgdmhjekgegd".toolbar_pin = "force_pinned"; # PiP View
            "eimadpbcbfnmbkopoojfekhnkhdbieeh".toolbar_pin = "force_pinned"; # Dark Reader
          };
        };

        # For later if I ever add something with a native-messaging companion app:
        # nativeMessagingHosts = [pkgs.keepassxc];

        preferences = {
          browser.show_forward_button = false;
          helium = {
            #completed_onboarding = true;
            browser = {
              layout = 2;
              show_avatar_button = false;
              show_back_button = false;
              show_reload_button = false;
              show_vertical_tabs_collapse_button = false;
              zen_mode = true;
              zen_mode_sidebar_pinned = true;
              zen_mode_top_chrome_pinned = true;
            };
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
