{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  llmAgents = inputs.t3.packages.${pkgs.stdenv.hostPlatform.system};
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
  claudeMcpConfig = pkgs.writeText "claude-mcp.json" (builtins.toJSON {
    mcpServers.computer_use = computerUse // {type = "stdio";};
  });
in {
  imports = [
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
    };
    instructions = ''
      # Global
      - Prefer the smallest complete root-cause solution. Actively remove unnecessary code, duplication, layers, dependencies and files within the task's scope. Prefer deletion or simplification over additions, without sacrificing required behavior, readability or performance. Rewrites are welcome when they reduce total integration and maintenance cost.
      - Before replacing architecture or dependencies, compare the current approach and supported integrations. Measure relevant performance claims and account for platform code, startup, package size, maintenance and uncertainty. Reconsider prototypes as fixes accumulate complexity. Change settled recommendations only with new evidence and explain it.
      - Write concise, natural prose without semicolons in documentation, including CLI help and generated manuals. Change README/docs only when requested or needed to keep usage accurate. Before staging, compare the complete documentation and help-text diff with the branch base and remove additions that do not answer an explicit documentation request or correct inaccurate existing usage. New features and review findings do not by themselves justify expanding documentation. Keep the existing structure and edit the relevant section or table. Omit change narration, obvious explanations and duplicated options or defaults already covered by config/help. Use short CLI help labels and inspect changed help output before committing, removing redundant parentheticals and implementation details. Comments explain non-obvious reasons and constraints, not what the code plainly does.
      - Preserve requested behavior during rewrites. Add compatibility code only when requested.
      - Use connected sentences instead of splitting related points into clipped statements such as "Use existing navigation. No separate mode." Keep useful bullet lists when revising prose.
      - Load paginated lists automatically as the user scrolls. Do not add manual "load more" buttons.
      - Enter the project's Nix environment before running project commands when available.
      - Do not add tests unless asked. Reproduce reported failures when practical and verify the same path after fixing them. Builds, mocks and headless checks do not prove live input, hardware or visible interaction. State verification gaps. Repeat successful checks only after relevant changes or unresolved concerns.
      - Use the Niri MCP thread workspace by default. It uses normal desktop apps without filesystem isolation. Use an isolated Niri session when filesystem separation is needed. The user's active browser may be used when requested. Preserve the user's existing browser windows and tabs. Close only task-owned tabs and windows that the user has not taken over or asked to keep, and never quit a shared browser process. X11 is not allowed. Start with list_windows and get_app_state, target a window explicitly and use coordinates from its latest screenshot. Use launch_app to start private applications. Accessibility actions require snapshot_id and element_index from get_app_state. Ask before using niri mcp --desktop to control the user's compositor or accessing live-session hardware. The current project is writable in the isolated session, while its home and application profiles are temporary and removed when the connection ends.
      - Use the installed Helium launcher (`helium --new-window`) with my existing profile, sign-ins, extensions and settings by default. Do not add `--user-data-dir`, change profile environment variables, use incognito or bypass the configured launcher unless I request a separate profile or isolation. For isolated browser work, use a separate profile and `--force-renderer-accessibility`. Never force a separate browser instance onto a live Chromium profile. Check installed browsers before fetching another.
      - When computer use needs human help, call request_handoff and tell me what to do on the host and exact workspace returned by get_session_state. Stay paused until I explicitly return control in chat, then call resume_session. Inspect the app again before continuing. Never resume just because a sign-in appears complete.
      - Discover available tools before declaring a capability unavailable, and verify it before claiming it works. In the isolated MCP, start with `list_windows` and `get_app_state`. Missing display variables are not proof of no desktop: inspect `systemctl --user show-environment` and session sockets under `XDG_RUNTIME_DIR`, using discovered values rather than guessed socket names.
      - Commit completed work automatically and stage only this task's changes. Before finishing, review this task's unpublished series: fold attempts, follow-up fixes, cleanup and related docs into the unpushed commit they belong to. Split independently useful changes and name commits for their final result, not the development sequence. Honor requested grouping. Verify publication status before rewriting. A request to clean up or squash history, or remove a feature, authorizes rewriting affected published history, including dropping a change and its revert. Do not ask separately for history-rewrite permission. Use force-with-lease for authorized force-pushes.
      - Check the target repository's instructions and conventions before writing commits or PR titles. In my own projects, use short lowercase past-tense commit messages. Follow upstream conventions in external projects, including my forks.
      - Never add AI attribution to commits or PRs. Preserve human authorship and contributor credit when adapting others' work.
      - Automatically babysit PRs opened from T3 Code. Address existing review findings, fix verified issues and CI failures, resolve conflicts, then call `watch_pull_request` and end the turn. Handle subsequent events without polling and stop when bot reviews and required checks pass on the latest commit.
      - Pull with rebase, resolve conflicts and drop changes already upstream. Do not create pull merge commits unless explicitly requested.
      - Do not push, publish, send messages or make other online changes unless explicitly requested. Publication and deployment authorization carries through related follow-up fixes. Read-only access is allowed.
      - Keep instructions and custom skills in `/home/grey/Projects/nixconf/modules/desktop/t3code.nix`. Do not create project `AGENTS.md` or `.agents/` files.

      # Host configuration
      - Identify the actual host with `hostnamectl` and `/etc/os-release` before inspecting or changing its configuration.
      - Before activation, compare the checkout, pins and intended changes with the running host. Capture the working system path, build once, retain the exact output and inspect the activation diff. Resolve unrelated removals, downgrades and service changes first.
      - Use actual Nix build outputs and verify executables exist. Fix Nix-managed services through modules, not manual units or runtime overrides.
      - Build remote hosts from their current nixconf checkout, never from saved snapshots or ad hoc files, and compare against the live `/run/current-system`. Run remote activation and rollback in detached `systemd-run` units with absolute tool paths, because restarting tailscaled ends `tailscale ssh` sessions mid-switch.
      - After activation, check affected services and authenticated client requests. On regression, restore and verify the captured working deployment before another fix. For the proxy carrying this session, keep independent recovery access and arrange automatic rollback unless client checks pass.
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
      - Keep computer-use, private-session startup and filesystem isolation in the Niri fork, with nixconf limited to package selection and MCP registration. Avoid extra compositor dependencies such as Sway.

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
        Prepare the text and a prefilled GitHub creation link, leaving final submission to me. Do not create or edit remote PRs or issues, including draft PRs, or use `gh pr create` even with `--web`. Keep unpublished text local. A link request does not authorize pushes, forks or uploads.

        Read the target repository's contribution rules, current template and title conventions. For PRs, review the complete diff and verify the base and head repositories, branches and published commits. For issues, check existing reports and establish the problem or requested improvement.

        Write in my voice:

        - Start with what bothered me and why I wanted the change, then explain what changed. Use first person only for experiences or intentions I've stated.
        - Prefer one or two short, conversational paragraphs with contractions and plain words. Avoid formal proposals and implementation inventories. Do not copy typos or force slang.
        - Explain a relevant downside and the choice it led to. End with a direct question when a maintainer decision is needed, without inventing tradeoffs or adding generic feedback requests.
        - For bugs, give the trigger, actual and expected behavior, and relevant versions, reproduction steps or workaround. For features, explain the missing capability, what I want and any concrete question about scope. Separate observations from suspected causes.
        - Preserve my revisions and explicit corrections. Titles follow the target repository's conventions. Avoid semicolons.

        Voice references: [dynamic casting](https://github.com/pantarune/niri-screenshare/pull/18), [Questify](https://github.com/Equicord/Equicord/pull/1397), [recording quality](https://github.com/noctalia-dev/official-plugins/pull/28) and [archive creation](https://github.com/sxyazi/yazi/issues/4471). Exclude obvious agent-written posts, including most T3 Code PRs, even when filed under my account.

        This is wording I explicitly approved, not a fixed template:

        > I noticed that I couldn’t switch monitors or windows while sharing in pickerless mode, so I added support for Niri’s dynamic cast. There’s also an option to automatically start on the focused monitor.
        >
        > One downside is that starting a new share with that option also switches existing dynamic shares to the focused monitor, so I kept the current pickerless mode. Let me know if you’d rather replace it.

        Keep required upstream sections and comments. Add headings, checklists or validation sections only when requested or required by the template. Fill fields from evidence and leave unsupported attestations unchecked. Do not invent testing or approval, or include task-status narration.

        Use a URL encoder, preserving newlines, Markdown and special characters:

        - PR: `https://github.com/OWNER/REPO/compare/BASE...HEAD_OWNER:HEAD_BRANCH?quick_pull=1&title=ENCODED_TITLE&body=ENCODED_BODY` for a fork, or `BASE...HEAD_BRANCH` within one repository. Include `HEAD_OWNER:HEAD_REPO:HEAD_BRANCH` when the fork needs a repository qualifier. Use the actual branch names and encode path components too.
        - Issue: `https://github.com/OWNER/REPO/issues/new?title=ENCODED_TITLE&body=ENCODED_BODY`. Select the appropriate template when required. For YAML issue forms, use `template=FILE.yml` and the supported field IDs as query keys instead of putting everything into `body`.

        Decode the URL locally to verify the destination, branches, title and full text. If the head is unpublished or stale, give the exact push command and explain the prerequisite. If URL limits or unsupported fields prevent full prefill, provide the complete text locally and identify the remaining manual steps. Do not call an incomplete link ready, truncate content or bypass required forms.

        Return a clickable "Review and submit PR" or "Review and submit issue" link and the title and body in the response or a local file. State that nothing was submitted. The link must open an editable creation form.
      '';
      # Adapted from https://github.com/mattpocock/skills/blob/a496f5513d4a4cf889bc48e189e579f4b0bdf6aa/skills/productivity/grilling/SKILL.md
      grill-me = ''
        ---
        name: grill-me
        description: "Use when unresolved tradeoffs need the user's input, or the user asks to be grilled."
        ---
        Inspect discoverable facts yourself. Map unresolved decisions and their dependencies, then ask the material questions whose prerequisites are settled. Number questions and give a recommendation with its reasoning. Challenge assumptions and tradeoffs, not already settled preferences.

        Wait for answers before dependent questions while continuing independent investigation. Stop when material choices are settled, summarize the direction and honor existing implementation authorization. Create documents only when requested.
      '';
      review = ''
        ---
        name: review
        description: "Use when a scoped change is ready for review, or the user asks to review a change, commit or diff."
        ---
        Stay read-only unless fixes are requested. Resolve the target repository and complete requested diff from the conversation, including relevant callers and uncommitted changes. Review a requested series as a whole, not only its last commit. Do not assume the thread's working directory is the target.

        Check correctness, integration and whether the change fixes the root cause. Verify findings against code or behavior and recommend the smallest complete fix. Distinguish defects from optional preferences. Report actionable findings with locations, evidence and impact, plus coverage gaps. Do not reopen settled findings without new evidence.
      '';
      audit-codebase = ''
        ---
        name: audit-codebase
        description: "Use when assessing a whole codebase or subsystem for recurring defects or unnecessary complexity, rather than a specific diff."
        ---
        Map the requested area and relevant callers. Investigate redundant layers, duplicated logic, dead code, speculative abstractions, stale compatibility and weak integration. Establish why something is unnecessary rather than assuming wrappers or absence checks are bad.

        Delegate substantial independent areas only when useful, using the current model unless the user requests another. Verify and deduplicate findings. Report evidence, locations, impact, the smallest proposed fixes and coverage gaps. Stay read-only unless implementation is requested.

        If scores are requested, define the rubric first and support ratings with evidence. Mark unassessed areas and report strengths without inventing precision.
      '';
      refine-change = ''
        ---
        name: refine-change
        description: "Use when optimizing or simplifying a change, or when a change or artifact needs a fix-and-review loop, including requests to refine-change or iterate to a clean result."
        ---
        Resolve the actual repository, complete change or artifact, intended behavior and relevant callers. Keep that scope. For rewrites, identify the behavior that must survive.

        Review the full scope once for correctness and unnecessary complexity, then fix supported findings and verify affected behavior. Prefer removing or simplifying code to adding helpers, guards or options. Track fixed, disputed and remaining findings in the existing plan or brief. The implementing agent owns the result: challenge findings that expand scope or add machinery without a demonstrated need, and explain rejected findings with evidence. Later rounds examine changed behavior and open findings, reusing valid checks and conclusions for unchanged areas.

        Use at most three review rounds by default. Stop earlier on a clean pass or only non-actionable feedback. Use one independent GPT-6.1 Sol reviewer when useful, with a fresh context, a scoped brief and no nested reviewers. Keep implementation on the current model unless the user requests another. If the requested reviewer is unavailable, report that rather than silently substituting. Do not accept findings merely to obtain agreement.

        Review and verification must cover the final behavior diff, including late fixes. If the budget ends or verification is unavailable, report unresolved concerns rather than implying approval. Extend only when the user asks for more rounds. Preserve the user's permissions and commit rules. Report the reviewer's actual verdict, rounds completed and unresolved or rejected findings with reasons. If no independent review ran, say so. Include verification gaps and commits.
      '';
      # Adapted from https://github.com/mattpocock/skills/blob/a496f5513d4a4cf889bc48e189e579f4b0bdf6aa/skills/engineering/diagnosing-bugs/SKILL.md
      diagnosing-bugs = ''
        ---
        name: diagnosing-bugs
        description: "Use when investigating a difficult bug, intermittent failure or performance regression."
        ---
        Establish the exact symptom and inspect relevant changes. Build and run a reproduction before relying on it, preferring existing commands, trace replay, differential checks or bisection. Confirm it detects the reported symptom, not merely a nearby failure. Minimize without losing the failure. For intermittent bugs, increase reproduction frequency. Measure performance baselines before edits.

        Rank plausible causes with falsifiable predictions. Change one variable at a time and use targeted diagnostics to distinguish causes. If reproduction is unavailable, report attempts and limits, then continue with evidence.

        Apply the smallest supported fix when authorized and check both the reproduction and original workflow. Redact secrets and remove temporary instrumentation. Report the cause, observed results and remaining uncertainty.
      '';
      remember-correction = ''
        ---
        name: remember-correction
        description: "Use after a recurring correction or a durable preference, or when the user asks to remember one."
        ---
        Record durable preferences, not one-off task details. Identify the cause and narrowest prevention. First check whether the rule already exists. If it does, address the enforcement failure instead of appending a synonym. Prefer a structural fix or existing check where practical, and a scoped instruction for preferences. Do not expand the task or add tests without authorization.

        Update the existing instructions or inline skill in `/home/grey/Projects/nixconf/modules/desktop/t3code.nix`. Keep general preferences in Global and project invariants in Projects. Follow the configuration validation and commit rules.
      '';
    };
  };
}
