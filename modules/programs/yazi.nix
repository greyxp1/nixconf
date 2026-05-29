{ ... }: {
  flake.nixosModules.yazi = { pkgs, ... }: {
    home-manager.users.grey = { ... }: {
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        shellWrapperName = "yazi";
        extraPackages = with pkgs; [ ripdrag trash-cli ];

        plugins = with pkgs.yaziPlugins; {
          inherit smart-enter jump-to-char full-border mount toggle-pane compress restore;
        };

        initLua = ''require("full-border"):setup({ type = ui.Border.ROUNDED })'';

        settings = {
          mgr = {
            ratio   = [ 1 2 5 ];
            sort_by = "natural";
          };
        };

        keymap.mgr.prepend_keymap = [
          { on = [ "<l>" ];   run = "plugin smart-enter";             desc = "Enter dir or open file"; }
          { on = [ "f" ];     run = "plugin jump-to-char";            desc = "Jump to filename starting with char"; }
          { on = [ "C" ];     run = "plugin compress";                desc = "Compress selected files"; }
          { on = [ "u" ];     run = "plugin restore";                 desc = "Restore last deleted file"; }
          { on = [ "<A-m>" ]; run = "plugin mount";                   desc = "Mount manager"; }
          { on = [ "<A-p>" ]; run = "plugin toggle-pane min-preview"; desc = "Hide/show preview pane"; }
          { on = [ "M" ];     run = "plugin toggle-pane max-preview"; desc = "Maximize/restore preview pane"; }
          { on = [ "<A-d>" ]; run = ''shell -- ripdrag --no-click --and-exit --icon-size 64 --target --all "$@" | while read -r fp; do cp -nR "$fp" .; done''; desc = "Drag-and-drop (bidirectional)"; }
        ];
      };
    };
  };
}
