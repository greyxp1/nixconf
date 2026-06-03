{...}: {
  flake.nixosModules.yazi = {pkgs, ...}: {
    home-manager.users.grey = {...}: {
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        shellWrapperName = "yazi";
        extraPackages = with pkgs; [ripdrag trash-cli];
        settings.mgr.ratio = [1 2 5];
        settings.mgr.sort_by = "natural";

        plugins = with pkgs.yaziPlugins; {
          inherit smart-enter jump-to-char full-border mount toggle-pane compress restore starship;
        };

        keymap.mgr.prepend_keymap = [
          {
            on = ["l"];
            run = "plugin smart-enter";
            desc = "Enter dir or open file";
          }
          {
            on = ["f"];
            run = "plugin jump-to-char";
            desc = "Jump to filename starting with char";
          }
          {
            on = ["C"];
            run = "plugin compress";
            desc = "Compress selected files";
          }
          {
            on = ["u"];
            run = "plugin restore";
            desc = "Restore last deleted file";
          }
          {
            on = ["<A-m>"];
            run = "plugin mount";
            desc = "Mount manager";
          }
          {
            on = ["<A-p>"];
            run = "plugin toggle-pane min-preview";
            desc = "Hide/show preview pane";
          }
          {
            on = ["M"];
            run = "plugin toggle-pane max-preview";
            desc = "Maximize/restore preview pane";
          }
          {
            on = ["<A-d>"];
            run = ''shell -- ripdrag --and-exit --target --all "$@" | while read -r fp; do cp -nR "$fp" .; done'';
            desc = "Drag-and-drop (bidirectional)";
          }
        ];

        initLua = let
          theme = fromTOML (builtins.readFile (builtins.fetchurl {
            url = "https://raw.githubusercontent.com/CoryCharlton/starship-configuration/master/starship.toml";
            sha256 = "sha256:0g0fs3j7rrk7v099xqni935c3w480nzr0i04ahav5riw03c1hxrd";
          }));
          starshipCfg = (pkgs.formats.toml {}).generate "starship-yazi.toml" (theme
            // {
              add_newline = false;
              format = builtins.replaceStrings ["\n$character"] [""] theme.format;
              character = {disabled = true;};
            });
        in ''
          require("full-border"):setup({ type = ui.Border.ROUNDED })
          require("smart-enter"):setup({ open_multi = true })
          require("starship"):setup({ config_file = "${starshipCfg}" })
        '';
      };
    };
  };
}
