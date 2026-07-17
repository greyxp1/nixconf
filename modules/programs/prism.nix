{inputs, ...}: {
  flake.homeModules.prism = _: let
    themeName = "Fluent-Dark";
  in {
    xdg.dataFile."PrismLauncher/iconthemes/${themeName}" = {
      source = "${inputs.prism-themes}/icons/${themeName}";
      recursive = true;
    };

    programs.prismlauncher = {
      enable = true;
      themes.${themeName} = "${inputs.prism-themes}/themes/${themeName}";

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
