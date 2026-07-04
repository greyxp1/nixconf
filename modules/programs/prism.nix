{
  flake.homeModules.prism = {pkgs, ...}: let
    themeName = "Fluent-Dark";

    fluentDarkTheme = pkgs.fetchFromGitHub {
      owner = "M3CHR0M4NC3R";
      repo = "Prism-Launcher-Themes";
      rev = "main";
      sha256 = "1r0nbcyj3yna4jh5qvflxmg25xcymilp00iw0adq6n54774bsz84";
    };

    fluentDarkIcons = pkgs.fetchFromGitHub {
      owner = "PrismLauncher";
      repo = "Themes";
      rev = "main";
      sha256 = "0gzkdzvkxz0s915dsj975l0b1xxk57vjm5jc1g9g80wmshia9aap";
    };
  in {
    xdg.dataFile."PrismLauncher/iconthemes/${themeName}" = {
      source = "${fluentDarkIcons}/icons/${themeName}";
      recursive = true;
    };

    programs.prismlauncher = {
      enable = true;
      themes.${themeName} = "${fluentDarkTheme}/themes/${themeName}";

      settings = {
        Language = "en_US";
        ApplicationTheme = themeName;
        IconTheme = themeName;
        AutomaticJavaDownload = true;
        AutomaticJavaSwitch = true;
        IgnoreJavaWizard = true;
        MaxMemAlloc = 8192;
        MinMemAlloc = 4096;
        MainWindowState = "AAAA/wAAAAD9AAAAAAAABEwAAAVJAAAABAAAAAQAAAAIAAAACPwAAAADAAAAAAAAAAEAAAAeAGkAbgBzAHQAYQBuAGMAZQBUAG8AbwBsAEIAYQByAwAAAAD/////AAAAAAAAAAAAAAACAAAAAQAAABYAbQBhAGkAbgBUAG8AbwBsAEIAYQByAQAAAAD/////AAAAAAAAAAAAAAADAAAAAQAAABYAbgBlAHcAcwBUAG8AbwBsAEIAYQByAAAAAAD/////AAAAAAAAAAA=";
        StatusBarVisible = false;
        ToolbarsLocked = true;
      };
    };
  };
}
