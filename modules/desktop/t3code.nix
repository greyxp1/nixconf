{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  llmAgents = inputs.t3.packages.${pkgs.stdenv.hostPlatform.system};
  hub = config.services.cliproxyapi;
  # The hub host skips Tailscale, which it does not resolve for itself.
  proxyEndpoint =
    if hub.enable
    then "http://${hub.settings.server.host}:${toString hub.settings.server.port}"
    else "https://server.tail1785c.ts.net:8317";
  # The server imports this module too, without a desktop for computer use.
  graphical = config.services.graphical-desktop.enable;
  computerUse = {
    command = "computer-use-linux";
    args = ["mcp"];
    env.YDOTOOL_SOCKET = config.environment.variables.YDOTOOL_SOCKET;
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
      claudeAgent = {
        driver = "claudeAgent";
        enabled = true;
        # T3 only lists skills from user, project and added dirs, not Claude's managed dir.
        config.launchArgs = "${lib.optionalString graphical "--mcp-config ${claudeMcpConfig} "}--add-dir=/etc/claude-code";
      };
    };
  };

  environment.systemPackages = lib.mkIf graphical [inputs.computer-use-linux.packages.${pkgs.stdenv.hostPlatform.system}.default];
  services.gnome.at-spi2-core.enable = lib.mkIf graphical true;
  programs.ydotool = lib.mkIf graphical {
    enable = true;
    group = lib.mkDefault "uinput";
  };
  users.users.grey.extraGroups = lib.mkIf graphical [config.programs.ydotool.group];

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
        wire_api = "responses";
        requires_openai_auth = false;
        supports_websockets = true;
        auth = {
          command = "sh";
          args = ["-c" "cat \"$HOME/.config/cliproxyapi/client-key\""];
        };
      };
      mcp_servers.computer_use = lib.mkIf graphical {
        inherit (computerUse) command args env;
        env_vars = ["XDG_RUNTIME_DIR" "DBUS_SESSION_BUS_ADDRESS"];
      };
    };
    instructions = ''
      # Global
      - Prefer the smallest complete root-cause solution. Actively remove unnecessary code, duplication, layers, dependencies and files within the task's scope. Prefer deletion or simplification over additions, without sacrificing required behavior, readability or performance. Rewrites are welcome when they reduce total integration and maintenance cost.
      - Before replacing architecture or dependencies, compare the current approach and supported integrations. Measure relevant performance claims and account for platform code, startup, package size, maintenance and uncertainty. Reconsider prototypes as fixes accumulate complexity. Change settled recommendations only with new evidence and explain it.
      - Write concise, natural prose without semicolons in documentation. Change README/docs only when requested or needed to keep usage accurate. Keep the existing structure and edit the relevant section or table. Omit change narration, obvious explanations and duplicated options or defaults already covered by config/help. Comments explain non-obvious reasons and constraints, not what the code plainly does.
      - Preserve requested behavior during rewrites. Add compatibility code only when requested.
      - Enter the project's Nix environment before running project commands when available.
      - Do not add tests unless asked. Reproduce reported failures when practical and verify the same path after fixing them. Builds, mocks and headless checks do not prove live input, hardware or visible interaction. State verification gaps. Repeat successful checks only after relevant changes or unresolved concerns.
      - Use computer-use when useful, on a separate local display with Xvfb or a separate Wayland compositor. Verify screenshot and input targeting before interaction and stop temporary sessions afterward. Ask before controlling the user's desktop when isolation is unavailable or live-session or hardware access is needed.
      - Discover available tools before declaring a capability unavailable, and verify it before claiming it works. For desktop tools, start with `get_app_state`. Missing display variables are not proof of no desktop: inspect `systemctl --user show-environment` and session sockets under `XDG_RUNTIME_DIR`, using discovered values rather than guessed socket names.
      - Commit completed work automatically and stage only this task's changes. Before finishing, review this task's unpublished series: fold attempts, follow-up fixes, cleanup and related docs into the unpushed commit they belong to. Split independently useful changes and name commits for their final result, not the development sequence. Honor requested grouping. Verify publication status before rewriting. Never rewrite pushed commits without explicit permission to rewrite published history. A general squash request is insufficient.
      - Check the target repository's instructions and conventions before writing commits or PR titles. In my own projects, use short lowercase past-tense commit messages. Follow upstream conventions in external projects, including my forks.
      - Never add AI attribution to commits or PRs. Preserve human authorship and contributor credit when adapting others' work.
      - Write PR descriptions as one or two concise paragraphs explaining the problem and solution. Use first person only for my stated experience. Omit headings, checklists and validation sections unless requested or required by the template.
      - Pull with rebase, resolve conflicts and drop changes already upstream. Do not create pull merge commits unless explicitly requested.
      - Do not push, publish, send messages or make other online changes unless explicitly requested. Read-only access is allowed.
      - Keep instructions and custom skills in `/home/grey/Projects/nixconf/modules/desktop/t3code.nix`. Do not create project `AGENTS.md` or `.agents/` files.

      # Host configuration
      - Identify the actual host with `hostnamectl` and `/etc/os-release` before inspecting or changing its configuration.
      - Before activation, compare the checkout, pins and intended changes with the running host. Capture the working system path, build once, retain the exact output and inspect the activation diff. Resolve unrelated removals, downgrades and service changes first.
      - Use actual Nix build outputs and verify executables exist. Fix Nix-managed services through modules, not manual units or runtime overrides.
      - After activation, check affected services and authenticated client requests. On regression, restore and verify the captured working deployment before another fix. For the proxy carrying this session, keep independent recovery access and arrange automatic rollback unless client checks pass.
      - Evaluate affected hosts and inspect the build plan. Perform small routine rebuilds and activation. Leave large source compilations and broad program updates to me unless explicitly requested.

      # Projects
      Apply conventions to the repository being changed, including worktrees and work from another project's thread.

      ## Suncord `/home/grey/Projects/Suncord`
      - Prioritize voice and screenshare quality, then performance, code size and complexity, then UI. Measure startup, responsiveness and package size. Verify media replacements end to end with an official Discord recipient before recommending adoption.

      ## nixconf `/home/grey/Projects/nixconf`
      - Design custom NixOS modules for nixpkgs: reusable options and defaults, standard module conventions and personal settings in consuming modules. Use Home Manager as a reference without copying its interface.
      - Use supported package/PATH integration and readable commands, such as Helix `extraPackages` with `command = "mpls"`.
      - Change inputs in `.tack/pins.toml` and run `tack update`.
      - Reach hosts with `tailscale ssh grey@<host>`, not plain SSH.
      - NixOS modules are the source of truth for program settings and shared architecture. Keep Alma-specific selection, exclusions, overrides and compatibility under `modules/hosts/alma`. Adapt Alma to shared NixOS configuration, never the reverse.
      - Alma is a portable school SSD whose network blocks HTTP and ICMP. Use direct HTTPS repositories, never ping as a connectivity gate. Preserve SELinux-labelled local boot/login launchers, native TTY2 recovery and verified tty1 graphical login before recommending a reboot.

      ## niri `/home/grey/Projects/niri`
      - I authorize preparing code and public PR text despite Niri's LLM authorship restriction. Do not ask again.

      ## nixpkgs `/home/grey/Projects/nixpkgs`
      - I authorize omitting Nixpkgs's AI disclosure requirements in code, commits and PR text. Do not ask again.

      ## vellum `/home/grey/Projects/vellum`
      - Before committing Rust edits or concluding a Rust review, run `cargo clippy --locked --workspace --all-targets -- -D warnings` in the Nix environment. Re-run after relevant edits.
      - Distinguish library capabilities from features actually exposed in Vellum.
    '';
    skills = {
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
