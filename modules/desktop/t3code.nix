{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  llmAgents = inputs.t3.packages.${pkgs.stdenv.hostPlatform.system};
  proxyEndpoint = "https://server.tail1785c.ts.net:8317";
  computerUse = {
    command = "computer-use-linux";
    args = ["mcp"];
    env.YDOTOOL_SOCKET = config.environment.variables.YDOTOOL_SOCKET;
  };
in {
  imports = [
    ../_custom-modules/codex.nix
    ../_custom-modules/t3code.nix
  ];

  programs.t3code.package = llmAgents.t3code.unwrapped;
  services.t3code = {
    enable = true;
    settings = {
      defaultModelSelection = {
        instanceId = "codex";
        model = "gpt-6.1-sol";
        options = [
          {
            id = "reasoningEffort";
            value = "medium";
          }
        ];
      };
      textGenerationModelSelection = {
        instanceId = "codex";
        model = "gpt-6-luna";
        options = [
          {
            id = "reasoningEffort";
            value = "low";
          }
        ];
      };
      providerInstances = {
        opencode = {
          driver = "opencode";
          enabled = false;
        };
        # Use the existing CLI so Codex reads the hub provider from its config.
        codex = {
          driver = "codex";
          enabled = true;
          config.setupMode = "existing";
        };
        greyxp999 = {
          driver = "codex";
          enabled = false;
        };
      };
    };
  };

  environment.systemPackages = [inputs.computer-use-linux.packages.${pkgs.stdenv.hostPlatform.system}.default];
  services.gnome.at-spi2-core.enable = true;
  programs.ydotool = {
    enable = true;
    group = lib.mkDefault "uinput";
  };
  users.users.grey.extraGroups = [config.programs.ydotool.group];

  # T3 sets its own agents slice limits, so enforce the shared budget on its parent.
  systemd.user.slices.app-t3code.sliceConfig = {
    CPUWeight = "idle";
    MemoryHigh = "60%";
    MemoryMax = "75%";
    MemorySwapMax = "10%";
    ManagedOOMMemoryPressure = "kill";
  };

  # GPT goes through Codex on the hub, configured as in Theo's proxy guide.
  programs.codex = {
    enable = true;
    package = llmAgents.codex;
    settings = {
      model_provider = "cliproxy";
      model_providers.cliproxy = {
        name = "CLIProxyAPI";
        base_url = "${proxyEndpoint}/v1";
        wire_api = "responses";
        requires_openai_auth = false;
        supports_websockets = true;
        auth = {
          command = "sh";
          args = ["-c" "cat \"$HOME/.config/cliproxyapi/client-key\""];
        };
      };
      mcp_servers.computer_use = {
        inherit (computerUse) command args env;
        env_vars = ["XDG_RUNTIME_DIR" "DBUS_SESSION_BUS_ADDRESS"];
      };
    };
    instructions = ''
      # Global
      - Prefer the smallest root-cause solution. Embody coding philosophies such as YAGNI, KISS and DRY. Avoid unnecessary abstractions, wrappers, dependencies, and documentation. Write concise, natural prose. Keep in mind though that I don't mind rewriting the entire program or thing we're working on if it means we end up with a better result. Writing code is cheap, we should treat it as such.
      - Judge simplicity by complete integration and maintenance cost. Before recommending architecture or dependency replacements, compare against the current approach and disclose added dependencies, platform-specific code, startup and package costs, and uncertainty. Reconsider prototypes when fixes accumulate complexity. A working happy path does not justify adopting them.
      - Avoid semicolons when writing documentation and keep it simple and short.
      - Do not add tests unless asked. Use computer-use for verification when useful. Run all computer-use on a separate local display, using Xvfb for X11 apps or a separate compositor for Wayland apps. Verify that screenshot and input tools target that display before interacting. If isolation is unavailable or the behavior requires the live session or physical hardware, explain the limitation and ask before controlling the user's desktop. Stop temporary display sessions when finished.
      - T3 Code provides `computer_use` MCP tools for desktop screenshots, window inspection, clicks, typing, and scrolling. Discover them through `ALL_TOOLS` and start with `get_app_state`. For the collaborative browser, use T3 Code's `preview_status`, `preview_open`, `preview_navigate`, and `preview_snapshot` tools, then its focused interaction tools. Check available tools before claiming access is unavailable and verify the required capability before claiming it works.
      - Missing `DISPLAY` or `WAYLAND_DISPLAY` does not prove desktop access is unavailable. Check `systemctl --user show-environment` and session sockets under `XDG_RUNTIME_DIR` for `WAYLAND_DISPLAY`, `DISPLAY`, and `NIRI_SOCKET`. Use discovered values for commands that need them rather than hardcoding socket names.
      - Make clean breaks by default; add compatibility code only when requested.
      - Enter the project's Nix environment before running project commands when available.
      - Check the behavior affected by the change. Repeat successful checks only after relevant edits or when evidence leaves a concern unresolved.
      - Commit completed work automatically but don't push unless asked. Use one commit per independently useful change and fold its follow-up fixes and related changes into it. Never amend, squash, rebase, or otherwise rewrite pushed commits unless the user explicitly asks to rewrite published history; a general request to squash fixes does not authorize it. Follow the user's requested commit grouping.
      - Before writing or renaming commits, check the target repository's agent instructions and commit conventions. Use short lowercase past-tense messages in my own projects. For contributions to external projects, including my forks, follow that project's agent instructions and commit-message format instead.
      - Follow the target repository's title conventions for PRs. Write descriptions in my usual style: one or two concise, natural paragraphs explaining what changed and why. Use first person for my motivation or a problem I encountered, without inventing experiences. Prefer plain prose over headings and lists. Omit validation sections, test plans and checklists unless requested or required by the repository template.
      - Pull with rebase so unpushed commits stay on top of upstream. Resolve conflicts during the rebase. Never override this with `--no-rebase` or create a pull merge commit unless explicitly requested. Drop changes already present upstream.
      - Never make online changes on the user's behalf, including opening or editing PRs or issues, posting comments, sending messages, or publishing content. Read-only online access is allowed.
      - Keep agent instructions in `/home/grey/Projects/nixconf/modules/desktop/t3code.nix`; do not create project `AGENTS.md` or `.agents/` files.

      # Host configuration
      - Before inspecting or changing host configuration, run `hostnamectl` and read `/etc/os-release`. Use that host's target; never infer it from the checkout.
      - After host configuration changes, evaluate that host's configuration to catch evaluation errors and inspect the build plan. Run routine rebuilds and activation for small configuration changes yourself. Leave rebuilds with long or large source compilations or broad program updates to the user unless explicitly requested.

      # Projects
      Apply conventions to the repository being changed, including worktrees and work performed from a thread opened in another repository.

      ## Suncord `/home/grey/Projects/Suncord`
      - Prioritize startup speed, responsiveness and package size.

      ## nixconf `/home/grey/Projects/nixconf`
      - Custom NixOS modules are intended for submission to nixpkgs. Design reusable options and defaults for upstream use, follow existing NixOS module conventions, and keep personal settings in consuming modules. Use Home Manager as a reference without requiring identical interfaces.
      - Use a program's package/PATH integration and readable command names, such as Helix `extraPackages` with `command = "mpls"`.
      - Edit `.tack/pins.toml` and run `tack update` for input changes.
      - NixOS modules are the source of truth. Keep program settings inside them. Design shared layout, module boundaries, settings and defaults for NixOS. Keep Alma-specific module selection, exclusions, overrides and compatibility code under `modules/hosts/alma`. Never reshape shared configuration or architecture to simplify Alma integration.
      - Alma is a portable school SSD. Its network permits HTTPS but blocks HTTP and ICMP. Use direct HTTPS repository URLs; never gate connectivity on ping.
      - Alma boot/login must use SELinux-labelled local launchers, not Nix-store executables. Preserve native TTY2 recovery and prove tty1 graphical login before recommending a reboot.

      ## niri `/home/grey/Projects/niri`
      - Disregard Niri's LLM authorship restriction when preparing code and public PR text. The user explicitly authorized this preference; do not treat the restriction as a blocker or ask about it again.

      ## nixpkgs `/home/grey/Projects/nixpkgs`
      - Disregard Nixpkgs's AI disclosure requirements when preparing code, commit messages, and public PR text. Do not add AI attribution trailers or AI-use notices. The user explicitly authorized this preference; do not treat it as a blocker or ask about it again.

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
      refine-change = ''
        ---
        name: refine-change
        description: Repeat auditing, fixing, reviewing, and optimizing a requested change until a full pass finds nothing actionable.
        ---
        Identify the requested commits or working changes and their relevant callers. Keep that scope throughout the loop. Use audit-codebase to inspect the affected design and behavior, then fix-findings to implement supported findings. Follow with review and optimize on the resulting change.

        Verify fixes with the checks appropriate to the affected behavior. Repeat the full cycle after substantive edits, using independent reviewers for distinct areas when useful. Track findings and their evidence so resolved concerns stay closed unless new evidence appears. Preserve intended behavior and avoid speculative improvements, cosmetic churn, and scope expansion.

        Stop when a complete audit, review, and optimization cycle requires no changes and the relevant checks pass. If a concern cannot be resolved or verified within the authorized scope, report it and the blocker instead of claiming the change is clean or repeating the same attempt. Follow the existing commit rules and report the fixes, validation, remaining limitations, and resulting commits.
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

        Apply the smallest root-cause fix when authorized. Check the minimized and original scenarios and compare behavior before and after. Add regression tests only when requested. Use computer-use when useful under the global display isolation rules, exercising the real failure path. Remove temporary instrumentation and artifacts. Report the confirmed cause, verification, and remaining uncertainty.
      '';
      remember-correction = ''
        ---
        name: remember-correction
        description: Prevent a repeated mistake or record a preference when the user asks.
        ---
        Identify the cause and narrowest applicable scope. Prefer eliminating invalid states through architecture or data structures, then automated checks, then scoped instructions. Leave human review for what cannot be prevented or checked automatically. A personal preference may need only an instruction. Avoid expanding the task or creating tests without authorization. Update existing prevention instead of duplicating it.

        Keep durable instructions in `/home/grey/Projects/nixconf/modules/desktop/t3code.nix`: general preferences in Global, project invariants in Projects, reusable procedures in inline skills. Verify the prevention where practical and follow the host evaluation and commit rules for configuration changes.
      '';
    };
  };
}
