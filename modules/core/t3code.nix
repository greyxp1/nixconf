{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  agentModels = {
    codex = "gpt-6.1-sol";
    claude = "claude-opus-5-5";
  };
  reasoningEffort = {
    codex = "medium";
    claude = "high";
  };
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  hub = config.services.cliproxyapi;
  clientKey = config.security.nix-secrets.secrets."cliproxyapi/client-key".path;
  # The proxy host uses loopback even when the public route is unavailable.
  proxyEndpoint =
    if hub.enable
    then "http://${hub.settings.server.host}:${toString hub.settings.server.port}"
    else "https://greyxp1.root.sx";
  # The server imports this module too, without a desktop for computer use.
  graphical = config.services.graphical-desktop.enable;
  computerUse = {
    command = "niri";
    args = ["mcp" "--workspace"];
  };
  browse = {
    command = lib.getExe config.programs.browse.package;
    env = config.programs.browse.environment;
    args = ["mcp"];
  };
  computerUseHooks.Stop = [
    {
      hooks = [
        {
          type = "command";
          command = "${lib.getExe config.programs.niri.package} mcp --check-cleanup";
          timeout = 3;
        }
      ];
    }
  ];
  completionCleanup = graphical && config.programs.niri.package.mcpCompletionCleanup or false;
  claudeMcpConfig = pkgs.writeText "claude-mcp.json" (builtins.toJSON {
    mcpServers =
      {
        computer_use = computerUse // {type = "stdio";};
      }
      // lib.optionalAttrs config.programs.browse.enable {
        browse = browse // {type = "stdio";};
      };
  });
in {
  imports = [
    ../_custom-modules/browse.nix
    ../_custom-modules/claude-code.nix
    ../_custom-modules/codex.nix
    inputs.t3code.nixosModules.default
  ];

  programs.t3code = {
    enable = true;
    package = inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.nightly;
    server = {
      enable = true;
      target = lib.mkIf graphical "graphical-session.target";
      connect.enable = true;
    };
    settings.providerInstances = {
      # Use the existing CLI so Codex reads the hub provider from its config.
      codex = {
        driver = "codex";
        config.setupMode = "existing";
      };
      claudeAgent = {
        driver = "claudeAgent";
        # T3 only lists skills from user, project and added dirs, not Claude's managed dir.
        config.launchArgs = "${lib.optionalString graphical "--mcp-config ${claudeMcpConfig} "}--add-dir=/etc/claude-code";
      };
    };
  };

  # T3 sets its own agents slice limits, so enforce the shared budget on its parent.
  systemd.user.slices.app-t3code.sliceConfig = {
    CPUWeight = "idle";
    MemoryHigh = "60%";
    MemoryMax = "75%";
    MemorySwapMax = "10%";
    ManagedOOMMemoryPressure = "kill";
    # Agents capped at MemoryHigh thrash the page cache and stall the disk for the whole
    # machine while staying under oomd's 60% default, so kill them sooner.
    ManagedOOMMemoryPressureLimit = "20%";
    ManagedOOMMemoryPressureDurationSec = "20s";
  };

  security.nix-secrets.secrets."cliproxyapi/client-key".owner = "grey";

  # Claude subscriptions are only used from Claude Code, as Theo's proxy guide requires.
  programs.claude-code = {
    enable = true;
    package = llmAgents.claude-code;
    settings = {
      hooks = lib.mkIf completionCleanup computerUseHooks;
      effortLevel = reasoningEffort.claude;
      env.ANTHROPIC_BASE_URL = proxyEndpoint;
      apiKeyHelper = "cat ${clientKey}";
      # Empty strings drop the Co-Authored-By trailer and the PR line.
      attribution = {
        commit = "";
        pr = "";
      };
    };
    inherit (config.programs.codex) instructions skills;
  };

  # GPT goes through Codex on the hub, configured as in Theo's proxy guide.
  programs.codex = {
    enable = true;
    package = llmAgents.codex;
    settings = {
      hooks = lib.mkIf completionCleanup computerUseHooks;
      model_reasoning_effort = reasoningEffort.codex;
      plan_mode_reasoning_effort = reasoningEffort.codex;
      model_provider = "cliproxy";
      model_providers.cliproxy = {
        name = "CLIProxyAPI";
        base_url = "${proxyEndpoint}/v1";
        model_catalog_url = "${proxyEndpoint}/v1/models?provider=codex";
        wire_api = "responses";
        requires_openai_auth = false;
        supports_websockets = true;
        # Upstream overloads can last minutes, and exponential backoff over ten retries spans about three.
        request_max_retries = 10;
        stream_max_retries = 10;
        auth = {
          command = "cat";
          args = [clientKey];
        };
      };
      mcp_servers.computer_use = lib.mkIf graphical {
        inherit (computerUse) command args;
        env_vars = ["XDG_RUNTIME_DIR"];
      };
      mcp_servers.browse = lib.mkIf (graphical && config.programs.browse.enable) browse;
    };
    instructions = ''
      # Global

      ## Engineering
      - Prefer the smallest complete root-cause solution. Remove unnecessary code, duplication, layers, dependencies and files within scope, and do not set options to their defaults. Simplify or rewrite when it lowers integration and maintenance cost while preserving required behavior, readability and performance. When porting or replacing something, keep every existing feature unless I agree to drop it. Add compatibility code only when requested.
      - Recommend the simplest reliable approach first and push back on decisions that a simpler one serves better, explaining the tradeoff instead of silently adding workarounds. Honor explicit constraints.
      - Before replacing architecture or dependencies, compare the current approach and supported integrations. Measure performance claims and account for platform code, startup, package size, maintenance and uncertainty. Reconsider prototypes as fixes add complexity. Change settled recommendations only with new evidence and explain why.
      - Keep runtime behavior in programs and supported display effects in the compositor. Nix packaging handles builds, installation and runtime dependencies. NixOS modules expose reusable options and defaults, translate them to program configuration and manage services. Our nixconf selects packages, enables features and supplies personal settings. Check existing program and compositor capabilities before adding code, and do not reimplement their behavior in Nix wrappers or derivations.
      - Do not add tests unless asked. Reproduce reported failures when practical and verify the same path after fixing them. Builds, mocks and headless checks do not prove live input, hardware or visible interaction, so state verification gaps. Repeat successful checks only after relevant changes.

      ## Writing and UI
      - Write concise, natural documentation, CLI help and manuals in connected sentences without semicolons, keeping useful bullet lists. Edit README/docs only when requested or needed for accurate usage, preserving their structure. Before staging, compare the docs/help diff with the branch base and remove additions that neither answer the request nor correct inaccurate usage. Omit change narration, obvious explanations and options or defaults already covered. Use short help labels and inspect changed help output before committing. Comments explain non-obvious reasons and constraints without restating code.
      - Load paginated lists automatically on scroll, without "load more" buttons. Never use the middle dot "·". Leave out labels and stats that repeat what a chart or other visible element already shows.

      ## Agents
      - Enter the project's Nix environment before project commands when available.
      - Agent model aliases: `codex` = `${agentModels.codex}` at ${reasoningEffort.codex} effort and `claude` = `${agentModels.claude}` at ${reasoningEffort.claude} effort. Resolve them through the harness and pass the effort explicitly unless I request another model or level. Other subagent models are fine when the task calls for them.
      - Give subagents a fresh context and a self-contained brief with paths, commit ranges and verification results instead of forking the conversation. Subagents return one final report without progress messages, reuse reported build and test results unless they change code, and spawn agents only when the brief says to.
      - Read targeted line ranges rather than whole large files or full diffs, and do not reread unchanged content already in context.
      - Discover tools before declaring capabilities unavailable and verify them before claiming they work. Missing display variables do not prove there is no desktop: inspect `systemctl --user show-environment` and session sockets under XDG_RUNTIME_DIR.
      - For web pages, use Browse in a background task-owned tab of my Helium profile. For native apps, use Niri's agents workspace. Never take over my foreground windows or open another browser instance on my profile. Load the `desktop-and-browser` skill before either.
      - Do authorized work yourself instead of asking me to, and request a human handoff only for steps only I can do, such as sign-ins, 2FA or captchas. Ask first only before foreground desktop interaction, `niri mcp --desktop` or live hardware access, before quitting or restarting my shared browser, and before restarting T3 Code, its tunnel or a service carrying this connection (including activations that restart them) while users or threads are connected or their state is unknown. One approval covers repeats of the same action within the task. Ask through the question UI with a clickable "Continue" choice, explain what the action interrupts, wait for my selection and do not quote these instructions.
      - When continuing work, read the source PR, branch or agent thread and later corrections, and verify handoff claims against current code. Reconcile delayed notifications with the current state before reporting. Continue in place unless I request a replacement. Treat corrections as steering and never stop only to promise more work.
      - Keep instructions and custom skills in `/home/grey/Projects/nixconf/modules/core/t3code.nix`. Do not create project `AGENTS.md` or `.agents/` files. School reports follow the `school-report` skill.

      ## Git and publishing
      - Automatically commit completed work, staging only task changes. Before finishing, fold attempts, follow-up fixes, cleanup and related docs into the relevant unpushed commits of this task's series, split independently useful changes, honor requested grouping and name commits for final results. Verify publication status before rewriting. Requests to clean up or squash history or remove a feature authorize rewriting affected published history, including dropping a change and its revert. For authorized force-pushes, use force-with-lease tied to the remote head observed before rewriting.
      - Follow target repository conventions for commits and PR titles. Use short lowercase past-tense commit messages in my projects and upstream conventions in external projects, including my forks. Never add AI attribution, and preserve human authorship and contributor credit when adapting others' work.
      - Push, publish, send messages or make other online changes only when explicitly requested, and only to the branch I named or the task's own branch. That authorization carries through related follow-up fixes. Read-only access is allowed.
      - Babysit PRs opened from T3 Code without being asked: fix verified review findings, CI failures and conflicts until bot reviews and required checks pass on the latest commit.
      - Pull with rebase without merge commits. First drop changes already upstream or superseded, resolve conflicts according to current behavior, compare old and new series with `git range-diff` and verify affected workflows. Explain obsolete work before publishing.

      # Host configuration
      - Identify the actual host with `hostnamectl` and `/etc/os-release` before inspecting or changing its configuration.
      - Before activation, compare the checkout, pins and intended changes with the running host. Capture the working system path, build once, retain the exact output and inspect the activation diff. Resolve unrelated removals, downgrades and service changes first.
      - Use actual Nix build outputs, verify executables exist and fix Nix-managed services through modules instead of manual units or runtime overrides.
      - Build remote hosts from their current nixconf checkout, never snapshots or ad hoc files. Run remote activation and rollback in detached systemd-run units with absolute tool paths, so they finish when the session drops.
      - After activation, check affected services and authenticated client requests. On regression, restore and verify the captured working deployment before another fix. Protect the proxy carrying this session with independent recovery access and automatic rollback unless client checks pass.
      - Evaluate affected hosts and inspect the build plan, then perform small routine rebuilds and activation. Leave large source compilations and broad program updates to me unless explicitly requested.

      # Projects
      Apply conventions to the repository being changed, including worktrees and work from another project's thread.

      ## Relay `/home/grey/Projects/Relay`
      - Keep Relay independent of Suncord.
      - Prioritize voice and screenshare quality, then performance, code size and complexity, then UI. Measure startup, responsiveness and package size. Verify media replacements end to end with an official Discord recipient before recommending adoption.
      - Dismiss dialogs with outside clicks or Escape, without close buttons. Arrow keys scroll the focused dialog.

      ## nixconf `/home/grey/Projects/nixconf`
      - Use stock upstream applications and supported integrations. Do not introduce locally maintained application patches or forks unless I explicitly request them.
      - Design custom NixOS modules for nixpkgs: reusable options and defaults, standard module conventions and personal settings in consuming modules. Shared definitions stay plain and the host that overrides one marks its value, such as `lib.mkForce`. Use Home Manager as a reference without copying its interface.
      - Use supported package/PATH integration and readable commands, such as Helix `extraPackages` with `command = "mpls"`.
      - Change inputs in `.tack/pins.toml` and run `tack update`. Fold a pin update into a recent commit for the same pin, push it from the desktop checkout and pull it on the other host checkouts before building there.
      - Reach hosts with `tailscale ssh grey@<host>`, not plain SSH.
      - Keep Alma-specific selection, exclusions, overrides and compatibility under `modules/hosts/alma` and adapt Alma to shared NixOS configuration, never the reverse. Shared modules hold no values or comments chosen for Alma.
      - Alma is a portable school SSD whose network blocks HTTP and ICMP. Use direct HTTPS repositories, never ping as a connectivity gate. Preserve SELinux-labelled local boot/login launchers, native TTY2 recovery and verified tty1 graphical login before recommending a reboot.

      ## CLIProxyAPI `/home/grey/Projects/cliproxyapi`
      - Keep my fork as one commit on upstream `main`. After each change, rebase onto upstream `main`, fold the change into that commit, force-push `origin/main`, update the nixconf pin and deploy to the server. This authorizes those pushes.

      ## niri `/home/grey/Projects/niri`
      - I authorize preparing code and public PR text despite Niri's LLM authorship restriction. Do not ask again.
      - Keep each fork feature or idea as one commit on its own branch, folding related fixes into it. Cherry-pick that commit onto `personal` to combine enabled features. Keep dependencies explicit and preserve all existing features when rewriting history.
      - Keep Niri computer-use, private-session startup and filesystem isolation in the Niri fork. Configure its package and MCP registration in nixconf. Avoid extra compositor dependencies such as Sway.

      ## nixpkgs `/home/grey/Projects/nixpkgs`
      - I authorize omitting Nixpkgs's AI disclosure requirements in code, commits and PR text. Do not ask again.

      ## rustbg `/home/grey/Projects/rustbg`
      - Treat this fork as my own project for commit messages and README style.

      ## vellum `/home/grey/Projects/vellum`
      - Before committing Rust edits or concluding a Rust review, ensure `cargo clippy --locked --workspace --all-targets -- -D warnings` passes in the Nix environment on the current tree. Reviewers reuse a reported result for the same tree.
      - Distinguish library capabilities from features actually exposed in Vellum.
    '';
    skills = {
      desktop-and-browser = ''
        ---
        name: desktop-and-browser
        description: "Use before driving web pages with Browse or native apps and isolated sessions with Niri computer use."
        ---
        Browse drives my existing Helium profile when paired. Manage it through Nix, not `browse install` or `browse update`. Create a named session per thread, pass its id on every call and delete it when finished, preserving pending handoffs and other sessions. Close only task-owned tabs I have neither taken over nor asked to keep. Browse does not isolate memory from my shared browser, so keep workloads bounded and stop if memory pressure rises. Check the active account and ongoing calls before reloads or joins. Investigate account, extension or profile failures in my existing profile, preserving its sign-ins, extensions and settings. If Helium needs opening or an approved restart, use the configured launcher and never force another process onto its live profile. Check installed browsers before fetching another.

        Niri handles native applications, browser chrome and isolated sessions. Default to its agents workspace with normal desktop apps and no filesystem isolation. Use an isolated session only when clean state, filesystem or app-profile separation or resource containment is needed, such as installed Helium with a temporary profile. The project stays writable while temporary home and app profiles disappear at disconnect. Prefer Wayland, or a private Xvfb display for isolated X11 work.

        Prefer accessibility snapshots and explicit semantic actions over screenshots and keyboard shortcuts. Capture screenshots only when coordinates or visual judgement need them, and hand long visual verification loops to a fresh subagent that returns a verdict. Inspect the intended field before typing or submitting. When Niri refuses keyboard input because a sibling window has focus, use Browse for web pages or accessibility for native apps. A Browse foreground restriction does not rule out Niri accessibility.

        For Niri handoffs, confirm the setup is ready and give the steps, host and exact workspace from `get_session_state`. A completed sign-in does not authorize resuming, so wait for me to return control. Inspect the app again after any handoff.
      '';
      school-report = ''
        ---
        name: school-report
        description: "Use when writing a school report, lab report or TP answers."
        ---
        Match the referenced format, using short numbered noun phrases such as "Configuration des interfaces d’Edge" with the action, device and network details. Put requested steps and commands under the matching questions. Use common Cisco CLI abbreviations and avoid long dashes.
      '';
      prepare-pr-or-issue = ''
        ---
        name: prepare-pr-or-issue
        description: "Use when preparing a PR or issue title, description, or prefilled link for me to review and submit myself."
        ---
        Prepare text and a prefilled GitHub creation link for me to review and submit. Keep unpublished text local. Do not create or edit remote PRs or issues, including drafts, or use `gh pr create` even with `--web`. Link requests do not authorize pushes, forks or uploads.

        Read repository contribution rules, the current template and title conventions. For PRs, review the complete diff and verify base and head repositories, branches and published commits. For issues, check existing reports and establish the problem or requested improvement.

        Write in my voice:

        - Lead with what bothered me and why I wanted the change, then the solution. Use first person only for stated experiences or intentions.
        - Prefer one or two short conversational paragraphs with contractions and plain words. Avoid formal proposals, implementation inventories, copied typos and forced slang.
        - Describe implemented changes as results, such as "Paths now use builtins.path", rather than instructions such as "Use builtins.path". Only describe the change and necessary problem context, omitting assurances about unchanged behavior. Explain unfamiliar UI labels in terms of the capability they provide and link relevant upstream guidance.
        - Explain a downside only when needed to assess the change. Ask a direct question when a maintainer decision is needed, without invented tradeoffs or generic feedback requests.
        - For bugs, give the trigger, actual and expected behavior and relevant versions, reproduction or workaround. For features, explain the missing capability, what I want and concrete scope questions. Separate observations from suspected causes.
        - Preserve my revisions and explicit corrections, follow repository title conventions and avoid semicolons.

        Voice references: [dynamic casting](https://github.com/pantarune/niri-screenshare/pull/18), [Questify](https://github.com/Equicord/Equicord/pull/1397), [recording quality](https://github.com/noctalia-dev/official-plugins/pull/28) and [archive creation](https://github.com/sxyazi/yazi/issues/4471). Exclude obvious agent-written posts, including most T3 Code PRs, even when filed under my account.

        Use this approved wording as a voice example rather than a template:

        > I noticed that I couldn’t switch monitors or windows while sharing in pickerless mode, so I added support for Niri’s dynamic cast. There’s also an option to automatically start on the focused monitor.
        >
        > One downside is that starting a new share with that option also switches existing dynamic shares to the focused monitor, so I kept the current pickerless mode. Let me know if you’d rather replace it.

        Retain required upstream sections and comments. Add headings, checklists or validation sections only when requested or required by the template. Fill fields from evidence, leave unsupported attestations unchecked and omit task-status narration. Do not invent testing or approval.

        URL-encode titles, bodies and path components, preserving newlines, Markdown and special characters. Use actual branch names:

        - PR: `https://github.com/OWNER/REPO/compare/BASE...HEAD_OWNER:HEAD_BRANCH?quick_pull=1&title=ENCODED_TITLE&body=ENCODED_BODY` for a fork, or `BASE...HEAD_BRANCH` within one repository. Include `HEAD_OWNER:HEAD_REPO:HEAD_BRANCH` when the fork needs a repository qualifier.
        - Issue: `https://github.com/OWNER/REPO/issues/new?title=ENCODED_TITLE&body=ENCODED_BODY`. Select the appropriate template when required. For YAML issue forms, use `template=FILE.yml` and the supported field IDs as query keys instead of putting everything into `body`.

        Decode the final response's URL locally to verify destination, branches, title and full text match the prepared description. For an unpublished or stale head, give the exact push command and prerequisite. If URL limits or unsupported fields prevent full prefill, provide the full text locally and remaining manual steps. Never call an incomplete link ready, truncate content or bypass required forms.

        Put the clickable "Review and submit PR" or "Review and submit issue" GitHub creation URL directly in the final response. Never substitute a local file containing the link. The title and body may be in the response or a local file. State that nothing was submitted.
      '';
      # Coupling framework adapted from https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md
      # Reviewer workflow adapted from https://github.com/t3dotgg/tstack/tree/1085050f3baed1ac724caa4a8166145fb2ac88af/skills
      review = ''
        ---
        name: review
        description: "Use when reviewing a change, commit or PR, auditing a codebase or subsystem, or requesting council from codex and claude."
        ---
        Stay read-only unless fixes are requested. Resolve the repository, intended behavior, requested scope and relevant callers. Review complete diffs and uncommitted work, treating a requested series as a whole. For audits, map the requested codebase or subsystem and mark unassessed areas. Advice and review-only requests need one pass.

        Use one independent codex reviewer when useful. Council uses a fresh codex reviewer and a fresh claude reviewer in parallel, even when the implementing agent uses one of them. Resolve shared model aliases and supported options through the harness. Report unavailable reviewers without substituting or calling a partial council complete.

        Give reviewers fresh contexts and scoped briefs with the repository, commit range or changed paths, relevant callers, concrete failure conditions and verification results, letting them read the diff themselves rather than pasting it. Allow inspection beyond touched files, keeping reviewers read-only with no nested agents or skill loading. Reviewers send one final report, rerunning builds or tests only to check a specific finding. Council's first pass gives both the same request and raw evidence without each other's conclusions. Missing or failed reviews are not approval.

        Check correctness, integration and root causes. For audits, ask whether pieces should change together. Find hidden links requiring coordination without an explicit contract, needless links forcing unrelated concerns to change together, and surplus such as dead code, redundant layers, speculative abstractions or stale compatibility. Support findings with callers, behavior and Git history rather than directory layout or similar code alone.

        When reviewing stateful behavior, identify states and transitions hidden across flags, callbacks, async operations and persisted data. Check invalid combinations, ownership, cancellation, retries and failure recovery. Recommend explicit states or transitions where they prevent concrete bugs or simplify reasoning. Preserve intended behavior and prefer the smallest complete fix.

        Treat special cases as requirement clues. Establish why wrappers, retries, platform branches or absence checks are unnecessary before removing them. Preserve useful comment invariants and distinct test coverage. Compare shared abstractions with smaller local fixes, accounting for complexity and integration cost.

        Verify and deduplicate findings, distinguishing introduced regressions, pre-existing defects and optional preferences. Report pre-existing defects separately and keep unrelated fixes out of scope. Identify the bug class and check relevant callers for other instances so one fix covers the supported scope. Judge findings by evidence and impact rather than votes or agreement, and never accept them just to end a review. Report locations, evidence, impact, proposed fixes and coverage gaps. In audits, group verified symptoms by root cause in the existing plan or report without creating a document unless requested. Delegate substantial independent subarea investigations only when useful, using the current model unless the user requests another.

        When implementing, establish relevant test, build and behavior baselines before edits and verify affected behavior after each cohesive fix. Investigate new failures before fixing or reverting, distinguishing regressions, brittle checks and environmental failures. Passing tests are evidence only for covered behavior.

        Finish once scope is covered and actionable findings are verified. Explain unresolved or rejected findings, defer speculative or marginal redesigns and revisit settled findings only with new evidence.

        Report independent reviewers' actual verdicts and useful disagreements when used. Score only when requested, defining the rubric first and supporting ratings with evidence. Report strengths without invented precision.
      '';
      refine-change = ''
        ---
        name: refine-change
        description: "Use when refining or simplifying a change or running a fix-and-review loop, including refinement with council."
        ---
        Resolve the repository, complete change or artifact, intended behavior and relevant callers. Keep that scope and identify behavior a rewrite must preserve. Advice and review-only requests remain read-only. Implement fixes only when authorized.

        Follow the `review` skill for reviewer selection, briefs and finding assessment, including council when requested. Keep implementation on the current model unless the user requests another.

        Review the full scope once for correctness and unnecessary complexity, then fix supported findings and verify affected behavior. Track fixed, disputed and remaining findings in the existing plan or brief. Own the result: challenge findings that expand scope or add machinery without demonstrated need, and explain rejections with evidence. Later rounds cover changed behavior and open findings, reusing valid checks and conclusions elsewhere.

        Use at most three rounds, counting a complete review pass as one round, including a parallel council pass. Stop earlier on a clean pass or only non-actionable feedback. If actionable findings remain at the cap, explain whether they point to an overly complicated approach and recommend simplifying it or state the unresolved blocker. Extend only when the user requests more rounds.

        Review and verify the final behavior diff, including late fixes. Report review results, rounds, accepted and rejected findings with reasons, verification gaps and commits. Disclose absent independent review or unresolved concerns at budget end without implying approval.
      '';
      # Adapted from https://github.com/mattpocock/skills/blob/a496f5513d4a4cf889bc48e189e579f4b0bdf6aa/skills/engineering/diagnosing-bugs/SKILL.md
      diagnosing-bugs = ''
        ---
        name: diagnosing-bugs
        description: "Use when investigating a difficult bug, intermittent failure or performance regression."
        ---
        Establish the exact symptom and inspect relevant changes. Build and run a reproduction before relying on it, preferring existing commands, trace replay, differential checks or bisection. Confirm it detects the reported symptom, minimize without losing the failure and increase reproduction frequency for intermittent bugs. Measure performance baselines before edits.

        Rank causes with falsifiable predictions. Compare custom integrations with the supported upstream path before attributing a shared failure to custom code. Change one variable at a time and use targeted diagnostics to distinguish causes. If reproduction is unavailable, report attempts and limits, then continue with evidence.

        For timing or lifecycle failures, trace the actual state transitions and identify which transition violates the intended behavior.

        Apply an authorized fix and check the reproduction and original workflow. Redact secrets, remove temporary instrumentation and report the cause, observed results and remaining uncertainty.
      '';
      remember-correction = ''
        ---
        name: remember-correction
        description: "Use after a recurring correction or a durable preference, or when the user asks to remember one."
        ---
        Record durable preferences rather than one-off details. Identify the cause and narrowest prevention. Prefer structural fixes, settings or existing checks over instructions. When a rule already covers the case, it failed to be followed, so make that rule clearer or shorter instead of restating it elsewhere. Write general rules rather than tool- or incident-specific ones, and keep the always-loaded instructions from growing by tightening or removing nearby text. Do not expand the task without authorization.

        Update shared instructions or inline skills, keeping general preferences in Global, project invariants in Projects and situational guidance in skills. Follow configuration validation and commit rules.
      '';
    };
  };
}
