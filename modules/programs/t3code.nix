{
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
      opencode.settings.permission = "allow";
      codex = {
        enable = true;
        context = ''
          # Global
          - Prefer the smallest root-cause solution. Avoid unnecessary abstractions, wrappers,
            dependencies, and documentation. Write concise, natural prose.
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
          - Keep agent instructions in
            `/home/grey/Projects/nixconf/modules/programs/t3code.nix`; do not create project
            `AGENTS.md` or `.agents/` files.

          # Host configuration
          - Before inspecting or changing host configuration, run `hostnamectl` and read
            `/etc/os-release`. Use that host's target; never infer it from the checkout.
          - After implementing NixOS configuration changes, build and switch that host's
            NixOS configuration. Never activate standalone Home Manager or another host.
            If privileges are unavailable, ask the user to rebuild.

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

          ## vellum `/home/grey/Projects/vellum`
          - The user's `vellum toggle` keybind must control either the installed overlay or
            a development build. Preserve that workflow when changing IPC or packaging.
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
            Verify the prevention where practical and follow the host build, switch, and commit
            rules for configuration changes.
          '';
        };
      };
    };
  };
}
