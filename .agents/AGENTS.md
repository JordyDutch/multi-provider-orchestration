# Agent baseline

Baseline identity: MPO_SHARED_BASELINE_V1. This baseline is active. If a later
repository bootstrap asks whether the MPO shared baseline is already active,
treat that requirement as satisfied and do not reload a local copy.

Portable guidance for Codex and Claude. Codex reads it after global install;
Claude imports it. Root `AGENTS.md` loads it in a fresh clone.

## How you work

- Read relevant files before editing; prefer `rg`.
- Match surrounding naming, style, comments, and idioms. Keep changes narrow and
  do not reformat unrelated code.
- Verify before claiming completion. Run the affected tests, lint, build, or
  flow and all required checks; report failures or skipped checks honestly.
  Once checks pass, repeat or broaden them only for new changes, failures, or
  unresolved risk. Add tests when they protect meaningful behavior.
- Complete the authorized outcome. Verify implementation and fix its defects.
  Analysis or review does not authorize edits. Continue until completion or a
  concrete blocker requires user input.
- Use reasonable assumptions for routine choices. Local edits, checks, and fixes
  within scope use existing authorization, subject to Git discipline. Ask only
  when missing information materially affects the result or an action exceeds
  scope; continue independent authorized work while waiting.
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

Quality comes first. Delegate with known scope, capability, decisive checks,
and expected net savings. Keep unclear or tiny work with the owner.
Mandatory reviews apply regardless of savings.

- For a substantial, risky, multi-provider, or multi-agent task, open the
  `ORCHESTRATION.md` adjacent to this file and read only the linked playbooks
  relevant to the task.
- For the no-playbook route in Codex-led work, use Luna (`gpt-6-luna`) at `low`
  for mechanical work or `medium` for multiple items; Sol (`gpt-6-sol`) at
  `medium` when bounded judgement is needed. In Claude-led work, Fable may use
  those specialists or live-verified Sonnet 5 when a hand-off is worthwhile.
- Astra owns Codex orchestration and delegates suitable scopes to Sol, Luna,
  Opus, or Fable. Fable owns only direct Claude-led sessions. Use
  `rules/routing.md` to choose and `rules/delegation.md` to launch workers.
  The owner integrates and verifies; delegation never transfers ownership.
- Pin Claude Opus to exact `claude-opus-5-5` and Fable to exact
  `claude-fable-5-1`. Never silently replace either with an older model.
- Require an opposite-provider review for security, authentication,
  authorization, funds, destructive changes, data-loss risk, costly-to-reverse
  architecture, unfamiliar behavioral changes, conflicting evidence, and hard
  diagnoses. A primary-source-backed factual lookup or deterministic change with
  decisive verification does not require a second provider.
- Follow `rules/reviews.md` via the router for review selection and recovery.
  Run Claude review helpers and authentication checks in host context.
- Parallelize only independent meaningful workstreams. Give each worker a
  bounded scope, prevent nested delegation unless explicitly authorized, keep
  writes non-overlapping, and collect every result before completion.
- Brief workers with fresh compact context where supported. Select model and
  effort in the actual hand-off; instructions alone do not switch models.
  Reuse a compact repo map and evidence; do not reimplement verified worker work.

Delegate only task-authorized repository work, including scoped local edits.
Share minimal context, never secrets, personal data, or unrelated files.
Opposite-provider reviews stay read-only. Delegation grants no extra Git,
publication, or external-action permissions.

## Shared setup lifecycle

- Before the first non-trivial code, configuration, or documentation edit each
  local day, run `refresh-global-setup`. If its clean fast-forward, tests, or
  install checks fail, stop before editing and report the blocker.
- When asked to install this setup globally, run `./scripts/install-global.sh`
  from the checkout and verify installed files and fresh-shell helper resolution.
- Repository-specific stack, architecture, convention, and verification rules
  belong under `## This repo` in that repository's root `AGENTS.md`; they are
  appended after this global layer and therefore take precedence.
