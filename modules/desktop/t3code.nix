{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  agentModels = {codex = "gpt-6.1-sol"; claude = "claude-opus-5-5";};
  reasoningEffort = {codex = "medium"; claude = "high";};
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  hub = config.services.cliproxyapi;
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
  computerUseHooks.Stop = [{
    hooks = [{
      type = "command";
      command = "${lib.getExe config.programs.niri.package} mcp --check-cleanup";
      timeout = 3;
    }];
  }];
  completionCleanup = graphical && config.programs.niri.package.mcpCompletionCleanup or false;
  claudeMcpConfig = pkgs.writeText "claude-mcp.json" (builtins.toJSON {
    mcpServers = {
      computer_use = computerUse // {type = "stdio";};
    } // lib.optionalAttrs config.programs.browse.enable {
      browse = browse // {type = "stdio";};
    };
  });
in {
  imports = [
    ../_custom-modules/browse.nix
    ../_custom-modules/claude-code.nix
    ../_custom-modules/codex.nix
    ../_custom-modules/t3code.nix
  ];

  programs.t3code.package = llmAgents.t3code.unwrapped;
  services.t3code = {
    enable = true;
    target = lib.mkIf graphical "graphical-session.target";
  };
  programs.t3code.settings = {
    providerInstances = {
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

  # Claude subscriptions are only used from Claude Code, as Theo's proxy guide requires.
  programs.claude-code = {
    enable = true;
    package = llmAgents.claude-code;
    settings = {
      hooks = lib.mkIf completionCleanup computerUseHooks;
      effortLevel = reasoningEffort.claude;
      env.ANTHROPIC_BASE_URL = proxyEndpoint;
      apiKeyHelper = "cat \"$HOME/.config/cliproxyapi/client-key\"";
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
          command = "sh";
          args = ["-c" "cat \"$HOME/.config/cliproxyapi/client-key\""];
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
      - Prefer the smallest complete root-cause solution. Remove unnecessary code, duplication, layers, dependencies and files within scope. Simplify or rewrite when it lowers integration and maintenance cost while preserving required behavior, readability and performance. Add compatibility code only when requested.
      - Push back on decisions and preferences when a simpler, more reliable approach better serves the goal. Explain the tradeoff and recommend that approach instead of silently adding workarounds. Honor explicit constraints.
      - Before replacing architecture or dependencies, compare the current approach and supported integrations. Measure performance claims and account for platform code, startup, package size, maintenance and uncertainty. Reconsider prototypes as fixes add complexity. Change settled recommendations only with new evidence and explain why.
      - Keep runtime behavior in programs and supported display effects in the compositor. Nix packaging handles builds, installation and runtime dependencies. NixOS modules expose reusable options and defaults, translate them to program configuration and manage services. Our nixconf selects packages, enables features and supplies personal settings. Check existing program and compositor capabilities before adding code, and do not reimplement their behavior in Nix wrappers or derivations.
      - Write concise, natural documentation, CLI help and manuals without semicolons. Edit README/docs only when requested or needed for accurate usage, preserving their structure. Before staging, compare the complete docs/help diff with the branch base and remove additions that neither answer the request nor correct inaccurate usage, including feature or review-driven additions. Omit change narration, obvious explanations and options or defaults already covered. Use short help labels and inspect changed help output before committing. Comments explain non-obvious reasons and constraints without restating code.
      - Use connected sentences rather than clipped fragments, and keep useful bullet lists.
      - Match school reports to the referenced format, using short numbered noun phrases such as "Configuration des interfaces d’Edge" with the action, device and network details. Put requested steps and commands under matching questions. Use common Cisco CLI abbreviations and avoid long dashes.
      - Load paginated lists automatically on scroll, without manual "load more" buttons.
      - Enter the project's Nix environment before project commands when available.
      - Agent model aliases: `codex` = `${agentModels.codex}`, `claude` = `${agentModels.claude}`. Resolve them through the harness to available providers and exact model IDs. Honor explicit model requests and allow other subagent choices when the task calls for them.
      - Use ${reasoningEffort.codex} reasoning effort for codex and ${reasoningEffort.claude} for claude in implementation, audits, reviews and delegated work unless I explicitly request another level. Pass the supported effort option explicitly instead of relying on catalog defaults or inherited levels.
      - Do not add tests unless asked. Reproduce reported failures when practical and verify the same path after fixing them. Builds, mocks and headless checks do not prove live input, hardware or visible interaction. State verification gaps. Repeat successful checks only after relevant changes or for unresolved concerns.
      - Use Niri for native applications, browser chrome and isolated sessions. Default to its agents workspace with normal desktop apps and no filesystem isolation. Use an isolated session when filesystem or app-profile separation is needed: the project stays writable, while temporary home and app profiles disappear at disconnect. Prefer Wayland, or a private Xvfb display for isolated X11 work. Start with list_windows and get_app_state, explicitly target a window and use its latest screenshot coordinates. Launch apps through launch_app. Accessibility actions require snapshot_id and element_index from get_app_state. Ask before niri mcp --desktop or live-session hardware access.
      - Use Browse for web pages in my existing Helium profile when paired. Manage it through Nix, not `browse install` or `browse update`. Create a named session per thread, pass its id on every call and delete it when finished, preserving pending human handoffs and other sessions. Preserve existing browser windows and tabs, closing only task-owned ones I have neither taken over nor asked to keep. Ask for explicit approval before quitting or restarting a shared browser, explain the affected windows and calls, then perform the approved restart yourself through the configured launcher.
      - Use Browse for bounded browser checks in task-owned tabs. Use isolated Niri with installed Helium and a temporary profile when clean state, profile separation or resource containment is needed. Browse controls tabs but does not isolate their memory from my shared browser. Keep shared-browser workloads bounded and stop them if memory pressure rises. Investigate account, extension or profile failures in my existing profile, preserving its sign-ins, extensions and settings. Use the configured launcher if Helium needs opening and never force another process onto its live profile. Check the active account and ongoing calls before reloads or joins. Check installed browsers before fetching another.
      - Request approvals and confirmations through the question or approval UI with a clickable "Done" or "Continue" choice. Wait for my explicit selection rather than a typed reply.
      - Prefer explicit semantic actions and editable targets over keyboard shortcuts. Inspect the intended field before typing or submitting. When Niri refuses keyboard input because a sibling window has focus, use Browse for web pages or accessibility for native apps. Use isolation only when the task needs it. Never bypass an input refusal with shell focus commands, workspace or output switching, or global input utilities. Foreground interaction requires my explicit authorization.
      - Request a human handoff only when no safe supported alternative exists. If permission is the only obstacle to a supported action, ask for approval to perform it yourself instead of asking me to do it. A Browse foreground restriction does not rule out native computer use. Check supported native accessibility and desktop tools first, use existing foreground approval or request it if missing, and perform the interaction yourself when supported. Use Browse's handoff for its pages and wait for my confirmation through that handoff. For Niri, confirm the setup is ready, call request_handoff and give the steps, host and exact workspace from get_session_state. Stay paused until I explicitly return control, then call resume_session. Inspect the app again after either handoff. If another session owns the handoff, wait for that thread. A completed sign-in does not authorize resuming.
      - Discover tools before declaring capabilities unavailable and verify them before claiming they work. Missing display variables do not prove there is no desktop: inspect systemctl --user show-environment and session sockets under XDG_RUNTIME_DIR, using discovered values rather than guessed socket names.
      - Before stopping, restarting or scheduling a restart of T3 Code, its tunnel or a service carrying this connection, check connected users and running threads. If either exists or cannot be checked, explain the interruption and affected threads in the question or approval UI and wait for explicit approval. Apply this to activation that restarts those services. A progress message is not approval, while an explicit restart request authorizes it.
      - Automatically commit completed work, staging only task changes. Before finishing, review this task's unpublished series and fold attempts, follow-up fixes, cleanup and related docs into the relevant unpushed commits. Split independently useful changes, honor requested grouping and name commits for final results. Verify publication status before rewriting. Requests to clean up or squash history or remove a feature authorize rewriting affected published history, including dropping a change and its revert, without separate permission. For authorized force-pushes, use force-with-lease tied to the remote head observed before rewriting.
      - Check target repository instructions and conventions before writing commits or PR titles. Use short lowercase past-tense commit messages in my projects and upstream conventions in external projects, including my forks.
      - Never add AI attribution to commits or PRs. Preserve human authorship and contributor credit when adapting others' work.
      - When continuing work, read the source PR, branch or agent thread and later corrections. Verify handoff claims against current code and preserve intended behavior. Reconcile delayed notifications with the current state before reporting failure or completion. Continue in place unless I request a replacement or separation protects unrelated work. Treat corrections as steering and continue authorized work without asking for another go-ahead. Do not end a turn merely promising to continue. Stop only when finished, blocked or awaiting required user input or approval.
      - Automatically babysit PRs opened from T3 Code. Address existing review findings, fix verified issues, CI failures and conflicts, then call watch_pull_request and end the turn. Handle subsequent events without polling, stopping when bot reviews and required checks pass on the latest commit.
      - Pull with rebase. First compare intent with current upstream behavior, check for superseding work and drop changes already upstream. Resolve conflicts according to current behavior, compare old and new series with git range-diff and verify affected workflows. Explain obsolete work before publishing. Do not create pull merge commits unless explicitly requested.
      - Push, publish, send messages or make other online changes only when explicitly requested. Publication and deployment authorization carries through related follow-up fixes. Read-only access is allowed.
      - Keep instructions and custom skills in `/home/grey/Projects/nixconf/modules/desktop/t3code.nix`. Do not create project `AGENTS.md` or `.agents/` files.

      # Host configuration
      - Identify the actual host with `hostnamectl` and `/etc/os-release` before inspecting or changing its configuration.
      - Before activation, compare the checkout, pins and intended changes with the running host. Capture the working system path, build once, retain the exact output and inspect the activation diff. Resolve unrelated removals, downgrades and service changes first.
      - Use actual Nix build outputs, verify executables exist and fix Nix-managed services through modules instead of manual units or runtime overrides.
      - Build remote hosts from their current nixconf checkout, never snapshots or ad hoc files, and compare with live `/run/current-system`. Use detached systemd-run units with absolute tool paths for remote activation and rollback because tailscaled restarts interrupt tailscale ssh sessions.
      - After activation, check affected services and authenticated client requests. On regression, restore and verify the captured working deployment before another fix. Protect the proxy carrying this session with independent recovery access and automatic rollback unless client checks pass.
      - Evaluate affected hosts and inspect the build plan. Perform small routine rebuilds and activation. Leave large source compilations and broad program updates to me unless explicitly requested.

      # Projects
      Apply conventions to the repository being changed, including worktrees and work from another project's thread.

      ## Suncord `/home/grey/Projects/Suncord`
      - Prioritize voice and screenshare quality, then performance, code size and complexity, then UI. Measure startup, responsiveness and package size. Verify media replacements end to end with an official Discord recipient before recommending adoption.
      - Dismiss dialogs with outside clicks or Escape, without close buttons. Arrow keys scroll the focused dialog.

      ## nixconf `/home/grey/Projects/nixconf`
      - Use stock upstream applications and supported integrations. Do not introduce locally maintained application patches or forks unless I explicitly request them.
      - Design custom NixOS modules for nixpkgs: reusable options and defaults, standard module conventions and personal settings in consuming modules. Use Home Manager as a reference without copying its interface.
      - Use supported package/PATH integration and readable commands, such as Helix `extraPackages` with `command = "mpls"`.
      - Change inputs in `.tack/pins.toml` and run `tack update`.
      - Reach hosts with `tailscale ssh grey@<host>`, not plain SSH.
      - NixOS modules are the source of truth for program settings and shared architecture. Keep Alma-specific selection, exclusions, overrides and compatibility under `modules/hosts/alma`. Adapt Alma to shared NixOS configuration, never the reverse.
      - Alma is a portable school SSD whose network blocks HTTP and ICMP. Use direct HTTPS repositories, never ping as a connectivity gate. Preserve SELinux-labelled local boot/login launchers, native TTY2 recovery and verified tty1 graphical login before recommending a reboot.

      ## niri `/home/grey/Projects/niri`
      - I authorize preparing code and public PR text despite Niri's LLM authorship restriction. Do not ask again.
      - Keep fork-specific changes on dedicated branches and cherry-pick selected changes onto `personal`.
      - Keep Niri computer-use, private-session startup and filesystem isolation in the Niri fork. Configure its package and MCP registration in nixconf. Avoid extra compositor dependencies such as Sway.

      ## nixpkgs `/home/grey/Projects/nixpkgs`
      - I authorize omitting Nixpkgs's AI disclosure requirements in code, commits and PR text. Do not ask again.

      ## vellum `/home/grey/Projects/vellum`
      - Before committing Rust edits or concluding a Rust review, run `cargo clippy --locked --workspace --all-targets -- -D warnings` in the Nix environment. Re-run after relevant edits.
      - Distinguish library capabilities from features actually exposed in Vellum.
    '';
    skills = {
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
      # Adapted from https://github.com/mattpocock/skills/blob/a496f5513d4a4cf889bc48e189e579f4b0bdf6aa/skills/productivity/grilling/SKILL.md
      grill-me = ''
        ---
        name: grill-me
        description: "Use when unresolved tradeoffs need the user's input, or the user asks to be grilled."
        ---
        Inspect discoverable facts yourself. Map unresolved decisions and dependencies, then ask material questions with settled prerequisites. Number them and recommend answers with reasons. Challenge assumptions and tradeoffs while honoring settled preferences.

        Wait for answers before dependent questions while investigating independently. Once material choices are settled, summarize the direction and honor existing implementation authorization. Create documents only when requested.
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

        Give reviewers fresh contexts and scoped briefs, including complete code diffs, relevant callers, concrete failure conditions and verification results. Allow inspection beyond touched files, keeping reviewers read-only with no nested agents. Council's first pass gives both the same request and raw evidence without each other's conclusions. Missing or failed reviews are not approval.

        Check correctness, integration and root causes. For audits, ask whether pieces should change together. Find hidden links requiring coordination without an explicit contract, needless links forcing unrelated concerns to change together, and surplus such as dead code, redundant layers, speculative abstractions or stale compatibility. Support findings with callers, behavior and Git history rather than directory layout or similar code alone.

        When reviewing stateful behavior, identify states and transitions hidden across flags, callbacks, async operations and persisted data. Check invalid combinations, ownership, cancellation, retries and failure recovery. Recommend explicit states or transitions where they prevent concrete bugs or simplify reasoning. Preserve intended behavior and prefer the smallest complete fix.

        Treat special cases as requirement clues. Establish why wrappers, retries, platform branches or absence checks are unnecessary before removing them. Preserve useful comment invariants and distinct test coverage. Compare shared abstractions with smaller local fixes, accounting for complexity and integration cost.

        Verify and deduplicate findings, distinguishing introduced regressions, pre-existing defects and optional preferences. Report pre-existing defects separately and keep unrelated fixes out of scope. Identify the bug class and check relevant callers for other instances so one fix covers the supported scope. Judge findings by evidence and impact rather than votes or agreement, and never accept them just to end a review. Report locations, evidence, impact, proposed fixes and coverage gaps. In audits, group verified symptoms by root cause in the existing plan or report without creating a document unless requested. Delegate substantial independent subarea investigations only when useful, using the current model unless the user requests another.

        When implementing, establish relevant test, build and behavior baselines before edits and verify affected behavior after each cohesive fix. Investigate new failures before fixing or reverting, distinguishing regressions, brittle checks and environmental failures. Passing tests are evidence only for covered behavior.

        Finish once scope is covered and actionable findings are verified. Explain unresolved or rejected findings, defer speculative or marginal redesigns and revisit settled findings only with new evidence.

        Report independent reviewers' actual verdicts and useful disagreements when used. Score only when requested, defining the rubric first and supporting ratings with evidence. Report strengths without invented precision. When changing review prompts, tools or models, occasionally check confirmed historical defects and known clean changes. Judge whether real bugs are caught and harmful suggestions avoided, not the number of findings.
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
        Record durable preferences rather than one-off details. Identify the cause and narrowest prevention. Check for an existing rule and fix enforcement failures instead of appending synonyms. Prefer structural fixes or existing checks where practical, using scoped instructions for preferences. Do not expand the task without authorization.

        Update shared instructions or inline skills, keeping general preferences in Global and project invariants in Projects. Follow configuration validation and commit rules.
      '';
    };
  };
}
