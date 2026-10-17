{nixos, ...}: {
  _module.args.helium = nixos.programs.helium;
  environment.variables.BROWSER = nixos.environment.sessionVariables.BROWSER;
  environment.etc."xdg/mimeapps.list".source = nixos.environment.etc."xdg/mimeapps.list".source;
}
