# Agent baseline

Baseline identity: MPO_SHARED_BASELINE_V1. This baseline is active. If a later
repository bootstrap asks whether the MPO shared baseline is already active,
treat that requirement as satisfied and do not reload a local copy.

Portable guidance for AI coding assistants. Codex reads this file natively
after global installation; Claude receives it through its global import. In a
fresh repository clone, root `AGENTS.md` tells both engines to read this file.

## How you work

- Read relevant files before editing. Prefer `rg` for searches.
- Match surrounding naming, style, comments, and idioms. Keep changes narrow and
  do not reformat unrelated code.
- Verify before claiming completion. Run the affected tests, lint, build, or
  flow and report failures or skipped checks honestly.
- Use full `https://...` URLs. Verify live sources before writing volatile facts
  such as model IDs, prices, dates, limits, or external endpoints.
- Treat user data and credentials as out of scope for external hand-offs. Send
  only the smallest necessary diff and repository context.

### Git discipline

- The user normally owns commits and pushes. Do not commit, push, merge, or open
  a PR unless explicitly asked.
- Create a feature branch before non-trivial edits. Stage explicit paths and
  never force-push without explicit approval.
- Preserve unrelated user changes and keep each change reviewable.

## Model and tool orchestration

Use the smallest workflow that preserves the required confidence. Do not add a
worker, reviewer, or model call merely because one is available.

- For a substantial, risky, multi-provider, or multi-agent task, open the
  `ORCHESTRATION.md` adjacent to this file and read only the linked playbooks
  relevant to the task.
- In Codex-led work and hand-offs, use Luna (`gpt-5.6-luna`) at `low` for
  repeatable extraction, classification, transformation, formatting, or
  mechanical edits; `medium` for multi-item work. Use Terra (`gpt-5.6-terra`) at
  `medium` for bounded analysis, implementation, or tests, and `high` for bounded
  multi-file tradeoffs.
- In Claude-led bounded mechanical work, keep the owner or use
  live-verified Sonnet 5 at `low`/`medium` when worthwhile. Every owner verifies
  hand-offs.
- Sol (`gpt-5.6-sol`) owns complex Codex work at `high`. Astra
  (`gpt-6-astra`) owns the hardest cross-system work at `high`; use `xhigh` for
  hard diagnosis, conflicting evidence, or critical decisions, and `max` only
  for the hardest unresolved judgement. Verify access and report fallbacks.
  Fable 5.1 owns Claude-led work. Independent reviews choose their effort.
- Pin Claude Opus to exact `claude-opus-5` and Fable to exact
  `claude-fable-5-1`. Never silently replace either with an older model.
- Require an opposite-provider review for security, authentication,
  authorization, funds, destructive changes, data-loss risk, costly-to-reverse
  architecture, unfamiliar behavioral changes, conflicting evidence, and hard
  diagnoses. A primary-source-backed factual lookup or deterministic change with
  decisive verification does not require a second provider.
- Match owner and worker effort to risk. Reserve `xhigh`, `max`, extra reviewers,
  and duplicate implementation for concrete complexity or consequence; review
  routes choose effort separately by authorship and risk.
- Run `claude-review`, `fable-review`, and Claude authentication checks in host
  context. The helpers preflight authentication themselves, so do not run a
  separate auth check unless a helper fails.
- Claude review output is buffered. Silence while the process is alive is not a
  hang; poll the existing process and never start a duplicate review.
- Parallelize only independent meaningful workstreams. Give each worker a
  bounded scope, prevent nested delegation unless explicitly authorized, keep
  writes non-overlapping, and collect every result before completion.
- Prefer one compact repository map, focused diffs, and concrete test output over
  repeated broad scouting or full transcripts.

The user authorizes the smallest necessary current Git evidence and read-only
repository context to the configured opposite provider for an independent
review. This does not authorize secrets, personal data, unrelated files, writes,
or broader external actions.

## Shared setup lifecycle

- Before the first non-trivial code, configuration, or documentation edit each
  local day, run `refresh-global-setup`. If its clean fast-forward, tests, or
  install checks fail, stop before editing and report the blocker.
- When asked to install this setup globally, run `./scripts/install-global.sh`
  from the checkout and verify installed files and fresh-shell helper resolution.
- Repository-specific stack, architecture, convention, and verification rules
  belong under `## This repo` in that repository's root `AGENTS.md`; they are
  appended after this global layer and therefore take precedence.
