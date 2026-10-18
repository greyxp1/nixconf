{
  config,
  lib,
  ...
}: let
  cfg = config.programs.yazi;
  bashIntegration = ''
    function ${cfg.shellWrapperName}() {
      local tmp cwd yazi_status
      tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
      command yazi "$@" --cwd-file="$tmp"
      yazi_status=$?
      IFS= read -r -d "" cwd < "$tmp" || :
      if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ]; then
        builtin cd -- "$cwd"
      fi
      command rm -f -- "$tmp"
      return "$yazi_status"
    }
  '';
in {
  options.programs.yazi = {
    enableBashIntegration = lib.mkEnableOption "Bash integration for Yazi" // {default = true;};
    enableFishIntegration = lib.mkEnableOption "Fish integration for Yazi" // {default = true;};
    enableZshIntegration = lib.mkEnableOption "Zsh integration for Yazi" // {default = true;};
    shellWrapperName = lib.mkOption {
      type = lib.types.str;
      default = "y";
      example = "yy";
      description = "Name of the shell function that changes directory when Yazi exits.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bash.interactiveShellInit = lib.mkIf cfg.enableBashIntegration bashIntegration;
    programs.zsh.interactiveShellInit = lib.mkIf cfg.enableZshIntegration bashIntegration;
    programs.fish.shellFunctions.${cfg.shellWrapperName} = lib.mkIf cfg.enableFishIntegration {
      modifiers.wraps = "yazi";
      body = ''
        set -l tmp (mktemp -t yazi-cwd.XXXXXX); or return
        command yazi $argv --cwd-file="$tmp"
        set -l yazi_status $status
        set -l cwd
        if read -z cwd < "$tmp"; and test "$cwd" != "$PWD"; and test -d "$cwd"
          builtin cd -- "$cwd"
        end
        command rm -f -- "$tmp"
        return $yazi_status
      '';
    };
  };
}
