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
      codex = {
        enable = true;
        context = ''
          # Global
          - Prefer the smallest root-cause solution; follow KISS, YAGNI, and DRY.
          - Do not add tests unless asked. Keep human-facing docs concise and natural.
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
          - Prefer readable command names when packages are guaranteed in `PATH`; For example,
            use "ghostty" instead of "''${pkgs.ghostty}/bin/ghostty".
          - Edit `.tack/pins.toml` and use `tack update` for input changes.
          - `systemConfigs.alma` is a portable school SSD used across different PCs. The school
            blocks outbound HTTP and ICMP but permits HTTPS: never use ping as a connectivity
            gate, and configure Alma repositories to use their direct HTTPS base URLs.
          - Alma boot and login paths must not execute Nix-store files directly because SELinux
            can deny them. Keep a native TTY2 recovery path, use SELinux-labelled local launchers,
            and prove the tty1 graphical login path before recommending a reboot.
        '';
        skills = {
          blast-radius = ''
            ---
            name: blast-radius
            description: >-
              Find what a change could break outside its diff and prove the key safety assumption.
              Use when asked about blast radius, regression risk, or whether a small-looking
              change is safe.
            ---
            Trace callers, configuration, persisted state, wire formats, dependencies, and
            downstream consumers. Identify the one or two assumptions safety depends on and prove
            them with the real code or authoritative value.

            Report the evidence, credible failure paths, cleared risks, and cheapest real-path
            check. Mark unknowns as unproven. Stay read-only unless the user asks for fixes.
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

            Edit only `/home/grey/Projects/nixconf/modules/programs/t3code.nix`. Put general
            preferences in Global, repository conventions in the matching Projects section, and
            reusable multi-step procedures in skills. Preserve concrete wording when clearest and
            do not generalize beyond the evidence. Build the correct system target and follow the
            global switch and commit rules.
          '';
          diagnosing-bugs = ''
            ---
            name: diagnosing-bugs
            description: >-
              Diagnose hard, recurrent, intermittent, or performance bugs with a reproducible
              feedback loop. Use after a first fix fails, when the symptom is unclear, or when the
              user explicitly asks to diagnose or debug.
            ---
            Build the tightest runnable signal for the exact symptom, preferring an existing
            command, replay, differential check, profiler, or temporary harness. Redact secrets
            and do not add a permanent test unless asked.

            Reproduce and minimize. Rank three to five falsifiable hypotheses with predictions,
            then test one variable at a time. Instrument only distinguishing boundaries and
            measure performance before changing it.

            If fixing is in scope, address the root cause, rerun the minimized and original
            scenarios, and remove temporary artifacts. If no reliable signal exists, report what
            is missing instead of guessing.
          '';
          principle-guard-the-context-window = ''
            ---
            name: principle-guard-the-context-window
            description: >-
              Protect reasoning quality when outputs, files, histories, or repeated reads are
              filling the context. Use for long-running tasks and large investigations.
            ---
            Every token must earn its place. Read selective ranges, constrain tool output,
            summarize evidence, and avoid replaying or rereading raw payloads. Work in bounded
            phases. After a stable verified slice, leave a compact state brief and suggest a fresh
            thread when practical.
          '';
          principle-prove-it-works = ''
            ---
            name: principle-prove-it-works
            description: >-
              Verify completed work against the real artifact or user-facing path before declaring
              it done. Use after implementation and before handoff or commit.
            ---
            Identify the most direct observation. Build or evaluate when needed, then run the
            feature, read the authoritative value, or exercise the full integration path. Inspect
            delegated artifacts. Prefer a cheap deterministic check without adding permanent tests
            unless asked. State what was proven, how, and what remains unverified.
          '';
          principle-sequence-verifiable-units = ''
            ---
            name: principle-sequence-verifiable-units
            description: >-
              Break migrations, sweeps, refactors, and other multi-step work into small units that
              each end in a real check. Use when a task spans several files, behaviors, or commits.
            ---
            Start from a known-good state. Make one coherent change, run the cheapest relevant
            check, and advance only when it passes. Keep each commit independently valid. Do not
            batch unrelated edits or defer all verification to the end.
          '';
          prototype = ''
            ---
            name: prototype
            description: >-
              Build the smallest throwaway artifact that answers an uncertain UI, state-model, or
              architectural question before production implementation. Use when competing designs
              are plausible or requirements keep changing.
            ---
            Name the decision and observable success criterion. Build the smallest isolated,
            trivial-to-run artifact; compare genuinely different variants when useful. Default to
            in-memory state and omit tests, production abstractions, persistence, and polish.

            Recommend a variant before changing production code. Carry over only validated
            behavior and remove the prototype unless the user asks to preserve it.
          '';
          unslop = ''
            ---
            name: unslop
            description: >-
              Rewrite public-facing prose to remove AI tells while preserving meaning and voice.
              Use when explicitly invoked with "unslop" or when polishing documentation, release
              notes, PR text, or other prose meant for people.
            ---
            Cut puffery, vague attribution, promotion, canned transitions, chatbot filler,
            excessive hedging, repetition, and generic conclusions. Prefer concrete facts, plain
            words, active voice, natural rhythm, and restrained formatting.

            Preserve meaning, formality, and opinionated voice. Finish by finding and fixing what
            still sounds generated without sterilizing the author.
          '';
          grill-with-docs = ''
            ---
            name: grill-with-docs
            description: >-
              Stress-test an ambiguous plan or design through a structured interview and record
              only durable terminology or decisions. Use only when explicitly invoked with
              "grill-with-docs" or a clear request to grill a high-cost decision.
            ---
            Build a decision tree. In each round, ask every question whose prerequisites are
            settled, number the questions, and give a recommended answer with its tradeoff.
            Discover environmental facts yourself; ask the user only for choices. Recompute the
            frontier after each reply and stop when no material assumption remains.

            Present the final decisions in chat. Update an existing human-facing document only
            when the decision naturally belongs there and benefits people; otherwise create
            nothing. Never write documentation solely as agent memory, and introduce no glossary
            or ADR system unless explicitly asked. Do not implement until the user confirms the
            shared understanding.
          '';
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
