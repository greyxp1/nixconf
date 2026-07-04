{
  flake.homeModules.prism = {
    programs.prismlauncher = {
      enable = true;
      settings = {
        MaxMemAlloc = 8192;
        MinMemAlloc = 4096
        StatusBarVisible = false;
        
      };

      icons = ["Fluent-Dark"];
      themes = ["Fluent-Dark"];
    };
  };
}
