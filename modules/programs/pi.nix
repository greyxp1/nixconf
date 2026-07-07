{...}: {
  flake.homeModules.pi = {pkgs, ...}: {
    programs.pi-coding-agent = {
      enable = true;
      extraPackages = [pkgs.nodejs];
      settings = {
        enableSkillCommands = true;
        quietStartup = true;
        editorPaddingX = 1;
        theme = "catppuccin-mocha";
        packages = [
          "git:github.com/DietrichGebert/ponytail"
          "npm:pi-web-access@0.13.0"
          "npm:@ujjwalgrover/pi-catppuccin"
          "npm:@fgladisch/pi-footer"
        ];
      };
      keybindings = {
        "tui.select.up" = ["up" "ctrl+k"];
        "tui.select.down" = ["down" "ctrl+j"];
        "tui.select.confirm" = ["enter" "ctrl+l"];
        "tui.select.cancel" = ["ctrl+c" "escape" "ctrl+h"];
        "app.thinking.cycle" = ["ctrl+t"];
        "app.model.cycleForward" = [""];
        "app.model.cycleBackward" = [""];
        "app.exit" = ["ctrl+c"];
      };
      context = ''
        # Grey's Pi Context
        Grey uses Pi for local NixOS configuration in `/home/grey/nixconf`.
        Use `nh os switch` for rebuilds. Do not suggest raw `nixos-rebuild switch` unless asked.
        Make the smallest correct declarative Nix change. Prefer existing modules over new files or abstractions.
        Never revert unrelated user changes.
        Do not run checks or tests after edits. Grey will rebuild and report any issues.
      '';
    };

    home.file.".pi/web-search.json".text = builtins.toJSON {
      provider = "auto";
      allowBrowserCookies = false;
      workflow = "none";
      webSearch.enabled = true;
    };
  };
}
