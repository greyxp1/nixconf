{inputs, ...}: {
  flake.nixosModules.t3code.networking.firewall.allowedTCPPorts = [3773];
  flake.homeModules.t3code = {config, ...}: {
    # journalctl --user-unit=t3code -b -n 50 | rg -i 'token|pairing'
    systemd.user.services.t3code = {
      Unit.Description = "T3 Code server";
      Install.WantedBy = ["default.target"];
      Service = {
        ExecStart = "t3 serve --host 0.0.0.0 --port 3773";
        ExecSearchPath = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin";
        TasksMax = 512;
        MemoryMax = "16G";
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
        WorkingDirectory = "%h";
      };
    };

    programs = {
      t3code.enable = true;
      codex = {
        enable = true;
        context = ''
          # Global
          - Prefer the smallest root-cause solution; follow KISS, YAGNI, and DRY.
          - Do not add tests unless asked. Keep human-facing docs concise and natural.
          - Never use computer-use for testing unless the user explicitly asks.
          - Treat every change as a clean break unless the user explicitly asks to preserve
            compatibility. Do not add aliases, deprecation paths, migrations, or compatibility
            shims by default.
          - Before inspecting, building, activating, or changing host configuration, identify the
            current host and operating system with `hostnamectl` and `/etc/os-release`; select the
            matching host target and never infer it from the repository or working directory.
          - Enter the project's Nix environment before the first project command when available.
          - Before evaluating a Git-backed flake after creating files, stage only the new
            in-scope paths; untracked files are excluded. Never stage unrelated work.
          - Commit completed edits automatically; never push. Split only independently useful
            changes. Before handoff, amend or squash all work and follow-up revisions from one
            task into one commit. Use short lowercase past-tense commit messages.
          - Never create agent-specific project files such as `AGENTS.md` or `.agents/`. Keep
            agent configuration in this module; add project documentation only for humans.
          - On NixOS, never activate standalone Home Manager or another host's configuration.
            Build and switch the matching NixOS host; if privileges are unavailable, ask the user
            to run `nh os switch`.

          # Projects
          Apply only the matching repository section.

          ## nixconf `/home/grey/Projects/nixconf`
          - When a program supports adding packages to its `PATH`, use that and configure readable
            command names. For example, use Helix `extraPackages` with `command = "mpls"`, not
            `command = "''${pkgs.mpls}/bin/mpls"`.
          - Edit `.tack/pins.toml` and use `tack update` for input changes.
          - `systemConfigs.alma` is a portable school SSD used across different PCs. The school
            blocks outbound HTTP and ICMP but permits HTTPS: never use ping as a connectivity
            gate, and configure Alma repositories to use their direct HTTPS base URLs.
          - Alma boot and login paths must not execute Nix-store files directly because SELinux
            can deny them. Keep a native TTY2 recovery path, use SELinux-labelled local launchers,
            and prove the tty1 graphical login path before recommending a reboot.
        '';
        skills = {
          unslop = inputs.cursor-plugins + "/pstack/skills/unslop";
          blast-radius = inputs.cursor-plugins + "/pstack/skills/blast-radius";
          diagnosing-bugs = inputs.mattpocock-skills + "/skills/engineering/diagnosing-bugs";
          grill-with-docs = inputs.mattpocock-skills + "/skills/engineering/grill-with-docs";
          principle-guard-the-context-window = inputs.cursor-plugins + "/pstack/skills/principle-guard-the-context-window";
          principle-prove-it-works = inputs.cursor-plugins + "/pstack/skills/principle-prove-it-works";
          principle-sequence-verifiable-units = inputs.cursor-plugins + "/pstack/skills/principle-sequence-verifiable-units";
          prototype = inputs.mattpocock-skills + "/skills/engineering/prototype";
          optimize = ''
            ---
            name: optimize
            description: >-
              Use when invoked with "optimize" or other variants like "optimization".
            ---
            Review the task diff and relevant commits with fresh eyes. Check correctness, UX,
            reliability, readability, performance, maintainability, and necessity. Remove dead
            code, duplication, redundant comments, and incidental complexity. If no improvement
            remains, leave the implementation unchanged and say so.
          '';
          remember-correction = ''
            ---
            name: remember-correction
            description: >-
              Turn a user correction into the smallest durable Codex rule in the central Nix
              configuration. Use when asked to "make sure this never happens again", remember a
              preference, or codify a correction for future agents.
            ---
            Identify the correction, preferred behavior, and narrowest scope where it always
            applies. Inspect existing context and skills first; update instead of duplicating.

            Edit only `/home/grey/Projects/nixconf/modules/programs/t3code/t3code.nix`. Put general
            preferences in Global, repository conventions in the matching Projects section, and
            reusable multi-step procedures in inline skills. Preserve concrete wording when
            clearest and do not generalize beyond the evidence. Build the correct system target
            and follow the global switch and commit rules.
          '';
          review = ''
            ---
            name: review
            description: >-
              Use when invoked with "review".
            ---
            Diagnose the problem before judging the implementation. Trace behavior end to end,
            reproduce it when practical, and inspect architecture, history, and upstream
            conventions only when material. Decide whether the implementation fixes the cause or
            a symptom, compare simpler native alternatives, and recommend the smallest complete
            solution with material tradeoffs. Stay read-only unless asked to implement.
          '';
        };
      };
    };
  };
}
