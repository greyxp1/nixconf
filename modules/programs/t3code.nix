{
  flake.nixosModules.t3code.networking.firewall.allowedTCPPorts = [3773];
  flake.homeModules.t3code = {
    programs = {
      t3code.enable = true;
      codex = {
        enable = true;
        context = ''
          # Global
          - Prefer the smallest root-cause solution. Follow KISS, YAGNI, and DRY.
          - Do not add tests unless asked. Keep docs concise, natural, and clear.
          - Use the project's Nix environment when available.
          - Before evaluating a Git-backed flake after creating files, stage only the new
            in-scope paths; untracked files are excluded. Never stage unrelated work.
          - Commit completed edits automatically but never push. Split independent changes,
            squash otherwise, and use short lowercase past-tense commit messages.

          # Projects
          Apply only the matching repository section.

          ## nixconf `/home/grey/Projects/nixconf`
          - Prefer readable command names when packages are guaranteed in `PATH`.
          - Edit `.tack/pins.toml` and use `tack update` for input changes.
        '';
        skills = {
          review = ''
            ---
            name: review
            description: Use when invoked with "review".
            ---
            Diagnose the underlying problem before judging the implementation. Trace the
            relevant behavior end to end, reproduce it when practical, and inspect the
            architecture, history, and upstream conventions when they materially affect the
            answer. Determine whether the proposed or current implementation solves the cause
            rather than a symptom or workaround. Compare simpler native alternatives and recommend
            the smallest solution that fully resolves the core problem, including material
            tradeoffs. Do not modify code unless explicitly asked to implement the result.
          '';
          optimize = ''
            ---
            name: optimize
            description: Use when invoked with "optimize".
            ---
            Review the complete task diff and relevant commits with fresh eyes. Check
            correctness, UX, reliability, readability, performance, maintainability, and
            whether every line is necessary to use the least amount of code as possible.
            Remove dead code, duplication, redundant comments, and incidental complexity.
            If no improvement remains, leave the implementation unchanged and say so.
          '';
        };
      };
    };
  };
}
