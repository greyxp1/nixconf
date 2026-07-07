{
  flake.homeModules.pi = {pkgs, ...}: {
    programs.pi-coding-agent = {
      enable = true;
      extraPackages = [pkgs.nodejs];
      settings = {
        enableSkillCommands = true;
        quietStartup = true;
        showHardwareCursor = true;
        enableInstallTelemetry = false;
        theme = "catppuccin-tui-mocha";
        footer = {preset = "minimal";};
        packages = [
          "git:github.com/DietrichGebert/ponytail"
          "npm:pi-web-access@0.13.0"
          "npm:@ayulab/pi-rewind"
          "npm:@hypabolic/pi-hypa"
          "npm:@smoose/pi-footer"
          "npm:pi-catppuccin-tui"
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
        After changing Nix config, run `nh os switch >/tmp/nh-os-switch.log 2>&1 || { tail -120 /tmp/nh-os-switch.log; exit 1; }`.
        Only run a tiny smoke test when it directly verifies the changed behavior.
        Never revert unrelated user changes unless asked.
      '';
    };

    home = {
      packages = [(pkgs.writeShellScriptBin "hypa" "exec \"$HOME/.pi/agent/npm/node_modules/@hypabolic/hypa/bin.js\" \"$@\"")];
      sessionVariables.HYPA_PI_MODE = "replace";

      file.".pi/agent/catppuccin-tui-state.json".text = builtins.toJSON {
        indicator = true;
        status = true;
        footer = true;
      };

      file.".pi/web-search.json".text = builtins.toJSON {
        provider = "auto";
        allowBrowserCookies = false;
        workflow = "none";
        webSearch.enabled = true;
      };

      file.".pi/agent/extensions/done.ts".text = ''
        import { spawn } from "node:child_process";
        import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

        export default function (pi: ExtensionAPI) {
          pi.on("agent_end", async () => {
            spawn("${pkgs.libnotify}/bin/notify-send", ["Pi", "Done"], {
              detached: true,
              stdio: "ignore",
            }).unref();
          });
        }
      '';
    };
  };
}
