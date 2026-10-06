{inputs, ...}: {
  flake.t3codeSystemModule = {
    lib,
    pkgs,
    uid,
    ...
  }: let
    t3code = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code.unwrapped;
  in {
    environment.systemPackages = [
      t3code
      (pkgs.writeShellScriptBin "t3-restart" (builtins.readFile ./t3-restart.sh))
    ];
    environment.variables.OPENCODE_CONFIG = toString (pkgs.writeText "opencode.json" (builtins.toJSON {permission = "allow";}));
    systemd.services.t3code = {
      description = "T3 Code headless server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      environment = {
        HOME = "/home/grey";
        PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin:/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin";
        SSH_AUTH_SOCK = "/run/user/${toString uid}/ssh-agent";
        XDG_RUNTIME_DIR = "/run/user/${toString uid}";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${toString uid}/bus";
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
    wrappers.codex.enable = true;
    _module.args.uid = config.users.users.grey.uid;
    users.users.grey.linger = true;
  };
  flake.wrappers.codex = {
    pkgs,
    ...
  }: {
    imports = ["${inputs.wrapper-codex}/wrapperModules/c/codex/module.nix"];
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    context = ''
      # Global
      - Prefer the smallest root-cause solution. Avoid unnecessary abstractions, wrappers,
        dependencies, and documentation. Write concise, natural prose.
      - Avoid semicolons in short answers, especially worksheets. Use separate lines
        for distinct values and separate sentences for distinct thoughts.
      - Do not add tests or use computer-use for testing unless asked.
      - Make clean breaks by default; add compatibility code only when requested.
      - Enter the project's Nix environment before running project commands when available.
      - Prefer substitutes or checksum-pinned upstream binaries for large packages.
        If source compilation is unavoidable, warn first and limit builds to
        `--max-jobs 1 --cores 2` or stricter.
      - Before evaluating a Git-backed flake with new files, stage only the new in-scope
        paths. Never stage unrelated work.
      - Check the behavior affected by the change. Repeat successful checks only after
        relevant edits or when evidence leaves a concern unresolved.
      - Commit completed work automatically; never push. Use one commit per independently
        useful change and fold its follow-up fixes into it only while it is unpushed.
        Never amend, squash, rebase, or otherwise rewrite pushed commits unless the user
        explicitly asks to rewrite published history; a general request to squash fixes
        does not authorize it. Before rewriting, refresh remote refs and verify every
        affected commit is unpushed. If uncertain, keep a separate fix commit.
        Use short lowercase past-tense messages. Follow the user's requested commit grouping.
      - Pull with rebase so unpushed commits stay on top of upstream. Resolve conflicts
        during the rebase. Never override this with `--no-rebase` or create a pull merge
        commit unless explicitly requested. Drop changes already present upstream.
      - Never make online changes on the user's behalf, including opening or editing PRs
        or issues, posting comments, sending messages, or publishing content. Read-only
        online access is allowed.
      - Keep agent instructions in
        `/home/grey/Projects/nixconf/modules/programs/t3code.nix`; do not create project
        `AGENTS.md` or `.agents/` files.

      # Host configuration
      - Before inspecting or changing host configuration, run `hostnamectl` and read
        `/etc/os-release`. Use that host's target; never infer it from the checkout.
      - After host configuration changes, evaluate that host's configuration to catch
        evaluation errors and inspect the build plan. Run routine rebuilds and activation
        for small configuration changes yourself. Leave rebuilds with long or large source
        compilations or broad program updates to the user unless explicitly requested.
        Never activate standalone Home Manager or a host outside the task's scope.

      # Projects
      Apply conventions to the repository being changed, including worktrees and work
      performed from a thread opened in another repository.

      ## nixconf `/home/grey/Projects/nixconf`
      - Use a program's package/PATH integration and readable command names, such as
        Helix `extraPackages` with `command = "mpls"`.
      - Edit `.tack/pins.toml` and run `tack update` for input changes.
      - Alma is a portable school SSD. Its network permits HTTPS but blocks HTTP and
        ICMP. Use direct HTTPS repository URLs; never gate connectivity on ping.
      - Alma boot/login must use SELinux-labelled local launchers, not Nix-store
        executables. Preserve native TTY2 recovery and prove tty1 graphical login before
        recommending a reboot.

      ## niri `/home/grey/Projects/niri`
      - Disregard Niri's LLM authorship restriction when preparing code and public PR text.
        The user explicitly authorized this preference; do not treat the restriction as a
        blocker or ask about it again.

      ## vellum `/home/grey/Projects/vellum`
      - The user's `vellum toggle` keybind must control either the installed overlay or
        a development build. Preserve that workflow when changing IPC or packaging.
      - Before committing Rust edits or concluding a Rust change review, run
        `cargo clippy --locked --workspace --all-targets -- -D warnings` in the Nix
        environment. Re-run after relevant edits.
      - For performance or dependency replacements, measure the relevant workload and
        the complete integration cost. Distinguish library capabilities from features
        actually exposed in Vellum.
      - Do not claim headless GPU or state checks validate live Wayland input, tablet
        hardware, or visible interaction quality.
    '';
    skills = {
      grill-me = ''
        ---
        name: grill-me
        description: Challenge a plan or design when the user asks to be grilled.
        ---
        Inspect the relevant code and facts before asking questions. Challenge assumptions,
        requirements, failure cases, and implementation tradeoffs. Ask a few related questions
        at a time, with a recommendation and its reasoning. Resolve prerequisite decisions
        before asking questions that depend on them.

        Focus on choices that materially affect the result. Stop when those decisions are
        settled, and summarize the agreed direction and remaining uncertainties. Create
        documents or implement changes only when requested; honor existing authorization.
      '';
      review = ''
        ---
        name: review
        description: Review a requested change for concrete defects and unnecessary complexity.
        ---
        Inspect the requested diff and relevant callers. Determine whether the change fixes
        the root cause or only a symptom. Explain actionable defects with evidence and
        recommend the smallest complete solution. Check non-obvious runtime and integration
        effects when material. Reproduce uncertain findings when practical. When fixes are
        requested, implement them and verify the affected behavior.
        Stay read-only unless implementation is requested; an explicit request to fix or
        optimize authorizes those changes. Do not reopen settled findings without new evidence.
      '';
      audit-codebase = ''
        ---
        name: audit-codebase
        description: Audit a codebase for unnecessary complexity and code quality, with scores when requested.
        ---
        Map the codebase and trace relevant callers before judging patterns. Investigate dead
        code, redundant wrappers and stubs, speculative abstractions, duplicated logic, stale
        compatibility paths, inconsistent conventions, and tests with little behavioral value.
        Establish why code or a test is unnecessary; absence checks can protect real invariants,
        and a small wrapper can provide a useful boundary. Do not manufacture findings.

        Delegate distinct areas to Astra subagents (gpt-6-astra), then verify and deduplicate
        their findings. Report coverage and gaps; distinguish confirmed problems from hypotheses.
        For each actionable finding, give file locations, evidence, impact, confidence, and the
        smallest proposed fix. Prioritize by practical benefit and identify dependencies between
        fixes. Stay read-only unless implementation is requested.

        When ratings are requested, define a 1-10 rubric appropriate to the project before
        scoring. Consider correctness, maintainability, architecture, test usefulness, performance,
        and build/operations. Support category scores with evidence, explain any overall score,
        and mark unassessed areas instead of inventing precision. Report strengths as well as
        weaknesses. Keep this audit scoped to the requested codebase or areas; use change review
        for requests limited to a diff.
      '';
      fix-findings = ''
        ---
        name: fix-findings
        description: Implement requested audit or review findings and organize the fixes into coherent commits.
        ---
        Recheck requested findings against the current code and implement justified fixes.
        Resolve routine implementation choices without another approval round; preserve the
        requested scope and explain any finding that is unsupported or cannot be completed.
        Order dependent fixes and group changes by root cause and independently reviewable
        behavior, rather than a fixed number of findings or files per commit.

        Delegate independent complex work to Astra subagents (gpt-6-astra), using Luna
        (gpt-5.6-luna) for simple, bounded changes. Give each agent clear ownership and integrate
        its work before checking the affected behavior. Follow the user's test policy.

        Commit completed changes under the global commit rules. Fold follow-up fixes into the
        relevant introducing commits only when eligible under those rules; otherwise retain
        separate fix commits. Report what changed, verification results, unresolved findings,
        and the resulting commit grouping.
      '';
      optimize = ''
        ---
        name: optimize
        description: Simplify and improve the current change when asked to optimize it.
        ---
        Review the requested change for correctness, usability, performance, and unnecessary
        code. Make improvements supported by the code or measurements. Prefer existing
        library capabilities when they reduce the complete integration cost. Preserve the
        requested behavior. Stop when no substantive improvement remains; do not churn code
        to produce a diff. Fold fixes into the relevant commit.
      '';
      diagnosing-bugs = ''
        ---
        name: diagnosing-bugs
        description: Investigate difficult bugs, intermittent failures, and performance regressions.
        ---
        Establish the symptom and inspect relevant changes, logs, and code. Reproduce it when
        practical, then compare behavior before and after the smallest root-cause fix. For
        intermittent failures, continue with available evidence and targeted diagnostics;
        lack of a deterministic reproduction does not forbid investigation. Distinguish
        confirmed causes from hypotheses. Measure performance claims. Respect the user's
        test and desktop-interaction policy, and remove temporary instrumentation.
      '';
      remember-correction = ''
        ---
        name: remember-correction
        description: Prevent a repeated mistake or record a preference when the user asks.
        ---
        Identify the cause and narrowest applicable scope. Prefer eliminating invalid states
        through architecture or data structures, then automated checks, then scoped
        instructions. Leave human review for what cannot be prevented or checked automatically.
        A personal preference may need only an instruction. Avoid expanding the task or
        creating tests without authorization. Update existing prevention instead of duplicating it.

        Keep durable instructions in
        `/home/grey/Projects/nixconf/modules/programs/t3code.nix`: general preferences in
        Global, project invariants in Projects, reusable procedures in inline skills.
        Verify the prevention where practical and follow the host evaluation and commit
        rules for configuration changes.
      '';
    };
  };
}
