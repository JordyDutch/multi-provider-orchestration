# Agent baseline

Portable, tool-agnostic guidance for AI coding assistants working in any
repository. Codex reads this file natively; Claude Code loads it via an import from
`CLAUDE.md`. This file is generic and safe to copy into any repo.
Project-specific rules (stack, conventions, gotchas) belong under `## This repo`
in this file so Codex and Claude receive the same instructions. Keep
`CLAUDE.md` for its import and any genuinely Claude-only rules. The project
section takes precedence over the portable baseline.

## How you work

- Read the relevant files before editing. Do not patch blind or from memory.
- Prefer `rg` for searching; avoid slow recursive `grep`/`find`.
- Match the surrounding code: naming, style, comment density, existing idioms.
  Do not reformat or "improve" unrelated code while making a targeted change.
- Make narrow, reviewable changes. Do not rewrite working systems for a small ask.
- Verify before claiming done. Run the project's build/lint/tests (or exercise
  the affected flow) and report the real result. If something failed or was
  skipped, say so. Do not report success you did not observe.
- Use full `https://...` URLs in data and docs, never bare hosts or handles.
- Do not guess time-sensitive facts. Verify against live sources (see below)
  before writing anything about dates, deadlines, prices, counts, programs,
  network parameters, contract addresses, or external links.

### Git discipline

- The user does their own commits and pushes. Make edits, verify, then stop.
  Do not `git commit`, `git push`, or open PRs unless explicitly asked.
- Never work directly on the default branch for non-trivial changes; branch first.
- Stage explicit paths. Do not `git add .` or `git add -A` unless the whole
  worktree is intentionally in scope. Never force-push without explicit approval.
- Keep commits small enough to review. Do not commit unrelated user changes.

## Working across tools and models

Prioritize the best reliable outcome. Use the strongest available model for the
stages where judgement changes the result, and specialized tiers for bounded
support work. Do not call every model merely because it exists. Read
`ORCHESTRATION.md` before a substantial, risky, or multi-agent task. When this
baseline is installed globally, read `~/.codex/ORCHESTRATION.md`; the short
version is:

- **Verify availability, not just installation.** Check `command -v claude`,
  `command -v codex`, both versions, authentication, and the live model catalog
  before pinning a model. Use the compact filtered catalog command in
  `ORCHESTRATION.md`; never load the raw `codex debug models` output into model
  context. Access can vary by account and Codex version.
- **Promote substantial work to a strong orchestrator.** In a Codex-led session,
  use GPT-5.6 Sol for planning, routing, integration, and final synthesis. In a
  Claude-led session, use Fable 5. If the active session is on another tier,
  switch models or invoke the orchestrator before delegation and again after
  worker/reviewer results for final synthesis. If that is unsupported, use the
  strongest available model and report the limitation.
- **Use both providers from either entrypoint.** Starting in Codex means Sol
  orchestrates and gives Claude/Fable or Opus at least one meaningful
  implementation, diagnosis, UX, or review task. Starting in Claude means Fable
  orchestrates and gives Codex/Terra/Sol at least one meaningful task. The
  non-owning orchestrator remains available as a specialist: Sol may ask Fable
  for a complex independent code or architecture review, and Fable may ask Sol
  for the corresponding Codex-side judgement. For every substantial task, both
  providers participate when installed and authenticated; a rubber-stamp
  hand-off does not count.
- **Use the GPT-5.6 family deliberately.** The verified Codex IDs are
  `gpt-5.6-sol` for orchestration and the hardest implementation or judgement;
  `gpt-5.6-terra` for read-heavy work, normal scoped implementation, and tests;
  and `gpt-5.6-luna` for clear, repeatable, mechanical work. Use the full ID so
  routing is explicit. Reverify when a newer family ships.
- **Match effort to consequence.** Luna `low`/`medium` handles inventory,
  extraction, and mechanical edits. Terra `medium`/`high` handles repository
  mapping and well-bounded worker tasks. Use Sol `high` for substantial
  orchestration and complex multi-file implementation, and `xhigh` for
  architecture, security, or final judgement. Reserve `max` for the hardest
  single-agent problems. Use `ultra` only as a top-level, bounded multi-agent run
  when the task divides cleanly; never nest it, and verify that the account
  supports it.
- **Cross-check substantial work independently.** If GPT/Codex implements, use
  Opus for normal strong review or Fable when the review needs
  orchestration-grade reasoning across complex code, architecture, or
  conflicting findings. If Claude implements, use Sol. Require the opposite
  provider for every substantial task, including read-only audits, research,
  diagnosis, planning, code, and user-facing changes. Use its strongest suitable
  tier for contracts, permissions, funds, security, data-loss risk, and
  costly-to-reverse architecture. Skip the second provider only for bounded,
  deterministic work with no behavioral or factual consequence, or when it is
  unavailable.
- **Delegate by fit without locking tiers to ownership.** Exactly one
  orchestrator owns the plan, integration, and final decision, but the other
  provider's orchestrator may serve as a bounded expert or reviewer. Use Terra
  for normal scoped backend work, tests, and repository analysis; Luna/Sonnet
  for mechanical support; Opus for complex implementation, frontend, and UX;
  Fable for complex cross-cutting Claude-side review; and Sol for the hardest
  technical or security-critical Codex-side work. The owning orchestrator
  verifies every returned result before use.
- **Keep hand-offs compact and independent.** Send the smallest relevant diff,
  files, constraints, and failing output; remove secrets first. Ask the reviewer
  to find defects and missing tests, not to agree. Parallel writers need
  separate worktrees or explicitly non-overlapping file ownership. From Codex,
  prefer `claude-review` when installed: it preflights Claude authentication,
  captures the current diff, and keeps the review read-only. Use
  `fable-review` when the independent review needs Fable's cross-cutting
  orchestration judgement.
- **Optimize routing without weakening the result.** Keep planning,
  implementation, hard diagnosis, and final review on the tier they need. Avoid
  repeated scouting, oversized context transfers, overlapping agents, and
  duplicate implementations unless comparing designs improves the decision.

If an engine or tier is unavailable or unauthenticated, use the best available
route and report which cross-check was skipped.

### Installing the baseline globally

- When the user asks to install or apply this setup globally, execute
  `./scripts/install-global.sh` from this checkout. Do not stop after describing
  the commands.
- The installer makes the same baseline available in every user repo by copying
  the shared rules and on-demand context into `~/.codex`, installing
  `claude-review`, `fable-review`, and `sol-review` into `~/.local/bin`, and adding
  `@~/.codex/AGENTS.md` to `~/.claude/CLAUDE.md`.
- Preserve all existing Claude-only instructions. The shared import must occur
  exactly once; never replace the whole Claude rules file.
- Verify the installed copies byte-for-byte and confirm a fresh shell resolves
  all three review helpers before reporting success.
