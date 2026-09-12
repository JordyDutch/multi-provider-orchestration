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
  flow and all required checks; report failures or skipped checks honestly.
  Once checks pass, repeat or broaden them only for new changes, failures, or
  unresolved risk. Add tests when they protect meaningful behavior.
- Complete the user's requested outcome. For implementation work, verify the
  result and fix defects caused by the change. Stay within the authorized scope;
  an analysis or review request does not authorize implementation. Continue until
  completion or a concrete blocker requires user input.
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

Use the smallest workflow that preserves the required confidence. Do not add a
worker, reviewer, or model call merely because one is available.

- For a substantial, risky, multi-provider, or multi-agent task, open the
  `ORCHESTRATION.md` adjacent to this file and read only the linked playbooks
  relevant to the task.
- For the no-playbook route in Codex-led work, use Luna (`gpt-5.6-luna`) at `low`
  for mechanical work or `medium` for multiple items; Terra (`gpt-5.6-terra`) at
  `medium` when bounded judgement is needed. In Claude-led mechanical work, keep
  the owner or use live-verified Sonnet 5 at `low`/`medium` when worthwhile.
- Astra owns Codex orchestration; Fable owns Claude orchestration. Detailed
  model roles, effort, and escalation live in `playbooks/routing.md` via the
  router. Small scopes may stay with the active owner, who verifies hand-offs.
- Pin Claude Opus to exact `claude-opus-5` and Fable to exact
  `claude-fable-5-1`. Never silently replace either with an older model.
- Require an opposite-provider review for security, authentication,
  authorization, funds, destructive changes, data-loss risk, costly-to-reverse
  architecture, unfamiliar behavioral changes, conflicting evidence, and hard
  diagnoses. A primary-source-backed factual lookup or deterministic change with
  decisive verification does not require a second provider.
- Follow `playbooks/reviews.md` via the router for review selection and recovery.
  Run Claude review helpers and authentication checks in host context.
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
