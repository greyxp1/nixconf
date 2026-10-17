{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.zsh;
  functions = pkgs.linkFarm "zsh-site-functions" (lib.mapAttrsToList (name: text: {
      inherit name;
      path = pkgs.writeText name text;
    })
    cfg.siteFunctions);
in {
  options.programs.zsh = {
    siteFunctions = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = {};
      description = "Autoloaded Zsh functions.";
    };
    historySubstringSearch.enable = lib.mkEnableOption "history substring search";
    loginShellFinish = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Commands run after interactive login initialization.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.zsh.interactiveShellInit = lib.mkMerge [
      (lib.mkBefore (lib.optionalString (cfg.siteFunctions != {}) ''
        fpath=(${functions} $fpath)
        autoload -Uz ${lib.escapeShellArgs (builtins.attrNames cfg.siteFunctions)}
      ''))
      (lib.mkAfter (lib.optionalString cfg.historySubstringSearch.enable ''
        source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
      ''))
    ];
    environment.etc.zlogin.text = cfg.loginShellFinish;
  };
}
