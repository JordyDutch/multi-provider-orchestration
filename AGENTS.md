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
  Claude-led session, use Fable 5.1 (`claude-fable-5-1`). If the active session
  is on another tier, switch models or invoke the orchestrator before delegation
  and again after worker/reviewer results for final synthesis. If that is
  unsupported, use the strongest available model and report the limitation.
- **Use both providers from either entrypoint.** Starting in Codex means Sol
  orchestrates and gives Claude via Fable 5.1 or Opus 5 (`claude-opus-5`) at
  least one meaningful implementation, diagnosis, UX, or review task. Starting
  in Claude means Fable orchestrates and gives Codex/Terra/Sol at least one
  meaningful task. The
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
- **Always pin Claude Opus to Opus 5.** Every Opus route means Claude Opus 5
  with the exact model ID `claude-opus-5`. Never use a bare `opus` alias, a
  `latest` alias, or an older Opus model ID. If `claude-opus-5` is unavailable,
  report that the Opus route was skipped instead of silently substituting an
  older Opus release.
- **Always pin Claude Fable to Fable 5.1.** Every Fable route means Claude Fable
  5.1 with the exact model ID `claude-fable-5-1`. Never use a bare `fable` alias,
  a `latest` alias, or the older `claude-fable-5`. If `claude-fable-5-1` is
  unavailable, report that the Fable route was skipped instead of silently
  substituting an older Fable release.
- **Treat silent Opus review output correctly.** `claude-review` buffers its
  final text, so no stdout while its process is alive is not evidence of a
  hang. Use `medium` effort for a normal review, keep polling the existing
  process, and do not launch a duplicate. Reserve `high` or `xhigh` for
  critical, security-sensitive, or genuinely complex review. After a real
  bounded timeout, retry Opus 5 once with only the exact diff and no repository
  tools; if that also fails, use Fable 5.1 and report the fallback. Never
  replace Opus 5 with an older Opus release.
- **Match effort to consequence.** Luna `low`/`medium` handles inventory,
  extraction, and mechanical edits. Terra `medium`/`high` handles repository
  mapping and well-bounded worker tasks. Use Sol `high` for substantial
  orchestration and complex multi-file implementation, and `xhigh` for
  architecture, security, or final judgement. Reserve `max` for the hardest
  single-agent problems. Use `ultra` only as a top-level, bounded multi-agent run
  when the task divides cleanly; never nest it, and verify that the account
  supports it.
- **Cross-check substantial work independently.** If GPT/Codex implements, use
  Opus 5 (`claude-opus-5`) for normal strong review or Fable when the review
  needs orchestration-grade reasoning across complex code, architecture, or
  conflicting findings. If Claude implements, use Sol. Require the opposite
  provider for every substantial task, including read-only audits, research,
  diagnosis, planning, code, and user-facing changes. Use its strongest
  suitable tier for contracts, permissions, funds, security, data-loss risk,
  and costly-to-reverse architecture. Skip the second provider only for
  bounded, deterministic work with no behavioral or factual consequence, or
  when it is unavailable.
- **Choose reviews dynamically, with a confidence margin.** The owning
  orchestrator classifies the actual change and chooses the reviewer; a helper
  name is not the decision. For every review that is warranted, choose one
  review-strength rung above the minimum that first appears sufficient:
  normal Codex-authored work -> Opus 5 at `high`; complex or cross-cutting
  Codex-authored work -> Fable 5.1 at `xhigh`; normal Claude-authored work ->
  Sol at `xhigh`; critical Claude-authored work -> Sol at `max`. For critical
  Codex-authored work, use Fable 5.1 at `xhigh` and add an Opus 5 review at
  `high` when a second independent Claude perspective materially reduces risk.
  Do not manufacture a review for an exempt deterministic task, and do not
  escalate beyond the highest supported safe rung merely to satisfy the rule.
- **Delegate by fit without locking tiers to ownership.** Exactly one
  orchestrator owns the plan, integration, and final decision, but the other
  provider's orchestrator may serve as a bounded expert or reviewer. Use Terra
  for normal scoped backend work, tests, and repository analysis; Luna/Sonnet
  for mechanical support; Opus 5 (`claude-opus-5`) for complex implementation,
  frontend, and UX; Fable for complex cross-cutting Claude-side review; and Sol
  for the hardest technical or security-critical Codex-side work. The owning
  orchestrator verifies every returned result before use.
- **Parallelize independent work proactively.** When a task contains two or
  more meaningful workstreams that can proceed without waiting on each other,
  start bounded agents and/or separate terminal processes concurrently when
  that will reduce wall-clock time. Give each worker explicit ownership, keep
  writes non-overlapping, cap fan-out to useful available capacity, and retain
  one orchestrator for integration and final verification. Delegated workers
  execute their assigned scope and do not fan out again unless the orchestrator
  explicitly authorizes bounded subdelegation. Stay sequential for dependencies,
  same-file edits, trivial tasks, or work whose coordination cost is likely to
  exceed the time saved. Collect every spawned process or agent result and
  report failures before declaring completion.
- **Keep hand-offs compact and independent.** Send the smallest relevant diff,
  files, constraints, and failing output; remove secrets first. Ask the reviewer
  to find defects and missing tests, not to agree. Parallel writers need
  separate worktrees or explicitly non-overlapping file ownership. From Codex,
  prefer `claude-review` when installed: it preflights Claude authentication,
  captures the current diff, and keeps the review read-only. Use
  `fable-review` when the independent review needs Fable's cross-cutting
  orchestration judgement.
- **Standing external-review authorization.** The user authorizes sending the
  smallest necessary current Git diff, status, and read-only repository context
  to the configured Claude or Codex review provider for an independent review.
  This authorization continues across tasks in this setup; no extra confirmation
  is needed for that normal review hand-off. Never include credentials, tokens,
  private keys, personal data, or unrelated files, and ask again before any
  external action that exceeds this narrow read-only review scope.
- **Refresh this shared setup daily before coding.** Before the first
  non-trivial code, configuration, or documentation change in each local
  calendar day, run `refresh-global-setup`. It checks the canonical
  `https://github.com/JordyDutch/multi-provider-orchestration` checkout, accepts
  only a clean fast-forward to `origin/main`, runs its tests, and reinstalls the
  verified global setup. If the canonical checkout is dirty, divergent, missing,
  or a check fails, do not overwrite it or begin the requested code change:
  report the blocked refresh and ask for direction. A successful daily refresh
  is recorded, so later coding tasks that day do not repeat it.
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
