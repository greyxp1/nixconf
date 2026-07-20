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
          "npm:context-mode"
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
        Prefer YAGNI: reuse existing code, stdlib/native features, smallest safe diff, and concise answers.
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
        import { execFileSync } from "node:child_process";
        import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

        let startWindow: number | undefined;
        const focusedWindow = () => {
          try {
            const out = execFileSync("niri", ["msg", "--json", "focused-window"]);
            const id = JSON.parse(out.toString()).id;
            return typeof id === "number" ? id : undefined;
          } catch {}
        };

        export default function (pi: ExtensionAPI) {
          pi.on("agent_start", () => startWindow = focusedWindow());
          pi.on("agent_end", () => {
            const endWindow = focusedWindow();
            if (startWindow && endWindow && startWindow !== endWindow) {
              process.stdout.write("\x1b]777;notify;Pi;Done\x1b\\");
            }
            startWindow = undefined;
          });
        }
      '';
    };
  };
}
