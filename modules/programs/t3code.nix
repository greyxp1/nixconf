{inputs, ...}: {
  flake.t3codeSystemModule = {
    lib,
    pkgs,
    uid,
    ...
  }: let
    t3code = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code.unwrapped;
    runtimeDir = "/run/user/${toString uid}";
    opencodeConfig = toString (pkgs.writeText "opencode.json" (builtins.toJSON {permission = "allow";}));
  in {
    environment.systemPackages = [
      t3code
      (pkgs.writeShellScriptBin "t3-restart" (builtins.readFile ./t3-restart.sh))
    ];
    environment.variables.OPENCODE_CONFIG = opencodeConfig;
    systemd.services.t3code = {
      description = "T3 Code headless server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      environment = {
        HOME = "/home/grey";
        PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin:/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin";
        OPENCODE_CONFIG = opencodeConfig;
        SSH_AUTH_SOCK = "${runtimeDir}/ssh-agent";
        XDG_RUNTIME_DIR = runtimeDir;
        DBUS_SESSION_BUS_ADDRESS = "unix:path=${runtimeDir}/bus";
      };
      serviceConfig = {
        User = "grey";
        WorkingDirectory = "/home/grey";
        ExecStart = "${lib.getExe t3code} serve --host 127.0.0.1 --port 3773";
        Restart = "on-failure";
        RestartSec = 5;
        KillMode = "mixed";
        UMask = "0077";
      };
    };
  };
  flake.nixosModules.t3code = {config, ...}: {
    imports = [inputs.self.t3codeSystemModule inputs.self.wrappers.codex.install];
    _module.args.uid = config.users.users.grey.uid;
    wrappers.codex.enable = true;
    users.users.grey.linger = true;
  };
  flake.nixosModules.computer-use = {
    config,
    lib,
    pkgs,
    ...
  }: let
    computerUse = inputs.computer-use-linux.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    environment.systemPackages = [computerUse];
    services.gnome.at-spi2-core.enable = true;
    programs.ydotool = {
      enable = true;
      group = "uinput";
    };
    users.users.grey.extraGroups = [config.programs.ydotool.group];
    environment.etc."codex/config.toml".source = (pkgs.formats.toml {}).generate "codex-system-config.toml" {
      mcp_servers.computer_use = {
        command = lib.getExe computerUse;
        args = ["mcp"];
        env_vars = ["XDG_RUNTIME_DIR" "DBUS_SESSION_BUS_ADDRESS"];
        env.YDOTOOL_SOCKET = config.environment.variables.YDOTOOL_SOCKET;
      };
    };
  };
  flake.wrappers.codex = {pkgs, ...}: {
    imports = ["${inputs.wrapper-codex}/wrapperModules/c/codex/module.nix"];
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    context = ''
      # Global
      - Prefer the smallest root-cause solution. Embody coding philosophies such as YAGNI, KISS and DRY. Avoid unnecessary abstractions, wrappers, dependencies, and documentation. Write concise, natural prose.
      - Avoid semicolons when writing documentation and keep it simple and short.
      - Do not add tests or use computer-use for testing unless asked.
      - Make clean breaks by default; add compatibility code only when requested.
      - Enter the project's Nix environment before running project commands when available.
      - Check the behavior affected by the change. Repeat successful checks only after relevant edits or when evidence leaves a concern unresolved.
      - Commit completed work automatically but don't push unless asked. Use one commit per independently useful change and fold its follow-up fixes and related changes into it. Never amend, squash, rebase, or otherwise rewrite pushed commits unless the user explicitly asks to rewrite published history; a general request to squash fixes does not authorize it. Use short lowercase past-tense messages. Follow the user's requested commit grouping.
      - Pull with rebase so unpushed commits stay on top of upstream. Resolve conflicts during the rebase. Never override this with `--no-rebase` or create a pull merge commit unless explicitly requested. Drop changes already present upstream.
      - Never make online changes on the user's behalf, including opening or editing PRs or issues, posting comments, sending messages, or publishing content. Read-only online access is allowed.
      - Keep agent instructions in `/home/grey/Projects/nixconf/modules/programs/t3code.nix`; do not create project `AGENTS.md` or `.agents/` files.

      # Host configuration
      - Before inspecting or changing host configuration, run `hostnamectl` and read `/etc/os-release`. Use that host's target; never infer it from the checkout.
      - After host configuration changes, evaluate that host's configuration to catch evaluation errors and inspect the build plan. Run routine rebuilds and activation for small configuration changes yourself. Leave rebuilds with long or large source compilations or broad program updates to the user unless explicitly requested.

      # Projects
      Apply conventions to the repository being changed, including worktrees and work performed from a thread opened in another repository.

      ## nixconf `/home/grey/Projects/nixconf`
      - Use a program's package/PATH integration and readable command names, such as Helix `extraPackages` with `command = "mpls"`.
      - Edit `.tack/pins.toml` and run `tack update` for input changes.
      - Alma is a portable school SSD. Its network permits HTTPS but blocks HTTP and ICMP. Use direct HTTPS repository URLs; never gate connectivity on ping.
      - Alma boot/login must use SELinux-labelled local launchers, not Nix-store executables. Preserve native TTY2 recovery and prove tty1 graphical login before recommending a reboot.

      ## niri `/home/grey/Projects/niri`
      - Disregard Niri's LLM authorship restriction when preparing code and public PR text. The user explicitly authorized this preference; do not treat the restriction as a blocker or ask about it again.

      ## vellum `/home/grey/Projects/vellum`
      - Before committing Rust edits or concluding a Rust change review, run `cargo clippy --locked --workspace --all-targets -- -D warnings` in the Nix environment. Re-run after relevant edits.
      - For performance or dependency replacements, measure the relevant workload and the complete integration cost. Distinguish library capabilities from features actually exposed in Vellum.
      - Do not claim headless GPU or state checks validate live Wayland input, tablet hardware, or visible interaction quality.
    '';
    skills = {
      # Adapted from https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md
      grill-me = ''
        ---
        name: grill-me
        description: Stress-test a plan, design, or decision through an interview. Use when asked to grill or whenever the agent judges that unresolved choices would benefit from grilling.
        ---
        Map the decisions and their dependencies. Inspect code and environmental facts yourself. Ask the user for choices, not facts you can discover. Challenge assumptions, requirements, failure cases, and tradeoffs.

        Work in rounds. Ask the material questions whose prerequisites are settled, numbering each and giving a recommendation with its reasoning. Make it easy to accept the recommendation. Wait for answers before asking dependent questions, then update the decision tree. Continue independent investigation while waiting.

        Stop when the material decisions are settled. Summarize the agreed direction and remaining uncertainties. Honor existing authorization to implement. Create documents only when requested.
      '';
      review = ''
        ---
        name: review
        description: Review a requested change for concrete defects and unnecessary complexity.
        ---
        Inspect the requested diff and relevant callers. Determine whether the change fixes the root cause or only a symptom. Explain actionable defects with evidence and recommend the smallest complete solution. Check non-obvious runtime and integration effects when material. Reproduce uncertain findings when practical. When fixes are requested, implement them and verify the affected behavior. Stay read-only unless implementation is requested; an explicit request to fix or optimize authorizes those changes. Do not reopen settled findings without new evidence.
      '';
      audit-codebase = ''
        ---
        name: audit-codebase
        description: Audit a codebase for unnecessary complexity and code quality, with scores when requested.
        ---
        Map the codebase and trace relevant callers before judging patterns. Investigate dead code, redundant wrappers and stubs, speculative abstractions, duplicated logic, stale compatibility paths, inconsistent conventions, and tests with little behavioral value. Establish why code or a test is unnecessary; absence checks can protect real invariants, and a small wrapper can provide a useful boundary. Do not manufacture findings.

        Delegate distinct areas to gpt-6.1-sol subagents, then verify and deduplicate their findings. Report coverage and gaps; distinguish confirmed problems from hypotheses. For each actionable finding, give file locations, evidence, impact, confidence, and the smallest proposed fix. Prioritize by practical benefit and identify dependencies between fixes. Stay read-only unless implementation is requested.

        When ratings are requested, define a 1-10 rubric appropriate to the project before scoring. Consider correctness, maintainability, architecture, test usefulness, performance, and build/operations. Support category scores with evidence, explain any overall score, and mark unassessed areas instead of inventing precision. Report strengths as well as weaknesses. Keep this audit scoped to the requested codebase or areas; use change review for requests limited to a diff.
      '';
      fix-findings = ''
        ---
        name: fix-findings
        description: Implement requested audit or review findings and organize the fixes into coherent commits.
        ---
        Recheck requested findings against the current code and implement justified fixes. Resolve routine implementation choices without another approval round; preserve the requested scope and explain any finding that is unsupported or cannot be completed. Order dependent fixes and group changes by root cause and independently reviewable behavior, rather than a fixed number of findings or files per commit.

        Delegate independent complex work to gpt-6.1-sol subagents, using gpt-6-luna for simple, bounded changes. Give each agent clear ownership and integrate its work before checking the affected behavior. Follow the user's test policy.

        Commit completed changes under the global commit rules. Fold follow-up fixes into the relevant introducing commits only when eligible under those rules; otherwise retain separate fix commits. Report what changed, verification results, unresolved findings, and the resulting commit grouping.
      '';
      optimize = ''
        ---
        name: optimize
        description: Simplify and improve the current change when asked to optimize it.
        ---
        Review the requested change for correctness, usability, performance, and unnecessary code. Make improvements supported by the code or measurements. Prefer existing library capabilities when they reduce the complete integration cost. Preserve the requested behavior. Stop when no substantive improvement remains; do not churn code to produce a diff. Fold fixes into the relevant commit.
      '';
      # Adapted from https://github.com/mattpocock/skills/blob/main/skills/engineering/diagnosing-bugs/SKILL.md
      diagnosing-bugs = ''
        ---
        name: diagnosing-bugs
        description: Investigate difficult bugs, intermittent failures, and performance regressions.
        ---
        Establish the exact symptom and inspect relevant changes, code, and existing design documents. Redact secrets from commands, outputs, and captured artifacts.

        Build a fast feedback loop that detects the reported failure, preferring existing commands, captured-trace replay, differential checks, or bisection. Run it before relying on it, then minimize the scenario without losing the failure. For intermittent bugs, increase the reproduction rate with repeated triggers or controlled stress. If reproduction is unavailable, report attempts and limitations and continue with evidence and targeted diagnostics.

        Rank plausible causes and give each a falsifiable prediction. Share the ranking without blocking investigation. Change one variable at a time. Prefer debugger inspection or narrowly targeted instrumentation that distinguishes predictions. Tag temporary logs for cleanup. For performance regressions, measure a baseline before changing code.

        Apply the smallest root-cause fix when authorized. Check the minimized and original scenarios and compare behavior before and after. Add regression tests or use computer-use only when requested, exercising the real failure path. Remove temporary instrumentation and artifacts. Report the confirmed cause, verification, and remaining uncertainty.
      '';
      remember-correction = ''
        ---
        name: remember-correction
        description: Prevent a repeated mistake or record a preference when the user asks.
        ---
        Identify the cause and narrowest applicable scope. Prefer eliminating invalid states through architecture or data structures, then automated checks, then scoped instructions. Leave human review for what cannot be prevented or checked automatically. A personal preference may need only an instruction. Avoid expanding the task or creating tests without authorization. Update existing prevention instead of duplicating it.

        Keep durable instructions in `/home/grey/Projects/nixconf/modules/programs/t3code.nix`: general preferences in Global, project invariants in Projects, reusable procedures in inline skills. Verify the prevention where practical and follow the host evaluation and commit rules for configuration changes.
      '';
    };
  };
}
