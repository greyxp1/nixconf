{nixos, ...}: {
  _module.args.helium = nixos.programs.helium;
  environment.variables =
    nixos.programs.browse.environment
    // {
      BROWSER = nixos.environment.sessionVariables.BROWSER;
    };
  environment.etc."xdg/mimeapps.list".source = nixos.environment.etc."xdg/mimeapps.list".source;
}
