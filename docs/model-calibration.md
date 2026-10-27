# Practical model calibration

Calibrate a routing decision when it would change how you work. Start with one
representative task and a decisive acceptance check. Compare at most two routes
on equivalent isolated inputs when there is a real choice to resolve.

## Procedure

1. Select a task from normal work: mechanical file changes, scoped behavior,
   diagnosis, or review. Apply the existing ownership and review rules.
2. Name the authorized read/write paths and acceptance criteria before launch.
   Run the acceptance check against the initial state when testing a bug fix.
3. Launch the selected exact model and effort with a compact brief. Record
   runtime confirmation separately from the requested settings.
4. The owner checks the result, runs acceptance, and inspects the complete diff
   for changes outside scope. Record required corrections and elapsed time.
5. Add observations from the next ten representative tasks as they arise.
   Revisit routing only when repeated comparable results justify a change.

Use this small record for each task; redact private data before any hand-off:

| Field | Record |
| --- | --- |
| Task and scope | Type, allowed paths, initial state |
| Route | Requested model/effort and observed runtime model/effort |
| Acceptance | Exact command/check and observed result |
| Scope | Intended files changed; unexpected changes |
| Rework | Corrections required before acceptance |
| Time and usage | Wall-clock time; reported usage when available |
| Decision | Keep route, investigate, or no conclusion |

Separate provider availability from task quality. A quota error is a blocked
run, not a model failure on the coding task. Keep elapsed time tied to the
specific environment; reported tokens alone do not establish monetary cost.
Prefer owner execution or a shell command for tiny deterministic work when a
handoff's startup and integration cost exceeds its value.

## Initial edit-route check: 2026-09-30

The owner created an isolated CommonJS fixture with a deliberate addition bug
in `lineTotal(unitPrice, quantity)`. Only `src/cart.js` was writable; tests and
a sentinel file had to remain byte-identical. The test failed before the edit.

GPT-6.1 Sol was requested and confirmed as `gpt-6.1-sol` at `high`, in an
ephemeral `workspace-write` Codex CLI 0.159.2 session. It changed exactly
`return unitPrice + quantity;` to `return unitPrice * quantity;`, leaving test
execution to the owner as instructed.

Owner acceptance with `node --test test/cart.test.js` passed these five
assertions:

```js
assert.equal(lineTotal(12, 3), 36);
assert.equal(lineTotal(12, 0), 0);
assert.equal(lineTotal(0, 3), 0);
assert.equal(lineTotal(12.5, 3), 37.5);
assert.equal(lineTotal(12, 1), 12);
```

SHA-256 checks confirmed unchanged tests and sentinel; a full file inventory
found no added files. No rework was required. The CLI command took 26.16 seconds
and reported 9,407 tokens used. This verifies the edit handoff and owner
acceptance flow; it does not establish comparative quality, speed, or cost.

Sonnet 5.5 was then checked on a fresh copy of the same initial fixture through
`sonnet-task --edit`, requesting `low`. The helper validated exact runtime model
`claude-sonnet-5-5` from the successful JSON result. The owner reran all five
assertions and checked file inventory and hashes: only the same expression
changed, tests and sentinel stayed byte-identical, and no rework was required.
The helper command took 15.32 seconds, including authentication and capability
preflight. Claude Code was 2.1.285. The result validates the model; it does not
echo the provider's applied effort. These single call times, with different
overheads and effort requests, are insufficient for a speed or cost ranking.

The first Sonnet attempt had been blocked by Claude's session limit before
inference. The helper returned failure, retained private error evidence, and
left its fixture unchanged. The successful retry followed the announced reset;
the blocked attempt is excluded from model-quality comparisons.

## Claude-native routing and advisor checks: 2026-10-20

These checks used Claude Code 2.1.304 from an Opus 5.5 entry session whose user
settings selected a Fable advisor.

- Workflow `agent()` calls requesting `sonnet`, `haiku`, `claude-sonnet-5-5`,
  and `claude-haiku-5-5` each reported the matching exact model ID from the
  worker's own system prompt. Calls without a model ran on `claude-opus-5-5`.
- The Agent tool's `model` parameter offered only aliases. The project had no
  `.claude/agents/` directory when the session started, so a definition
  written there later was unavailable. Claude Code documents this
  new-directory exception and otherwise reloads changed definitions.
- A project agent with `model: claude-haiku-5-5`, launched from a
  `claude-sonnet-5-5` print session, produced `modelUsage` keys for both
  models. The Haiku worker answered `4` when asked to count the lines of a
  three-line file; route counts to a command.
- A restricted Haiku 5.5 print run with
  `--settings '{"advisorModel":"claude-fable-5-1"}'` returned `modelUsage`
  keys `claude-haiku-5-5` and `claude-fable-5-1` and a `usage.iterations` entry
  of type `advisor_message`. The single advisor call read 8,297 input tokens
  for a trivial prompt, because it reads the whole context.
- The repository `haiku-task` helper without `--advisor` reported no advisor
  tool despite the user setting, confirming that restricted mode ignores it
  (5.96 seconds). With `--advisor` it consulted Fable once and reported
  `advisor=claude-fable-5-1 (called)` (14.93 seconds).
- In Claude Code 2.1.304, a restricted print run with the prompt `/advisor`
  returned locally with cost 0 and empty `modelUsage`. With the Fable setting it
  printed `Advisor: Fable 5.1` and the allowed aliases. With
  `CLAUDE_CODE_DISABLE_ADVISOR_TOOL`, `CLAUDE_CODE_USE_BEDROCK`, or
  `DISABLE_TELEMETRY` in the settings `env` block it printed `/advisor isn't
  available in this environment.`; an `availableModels` list without Fable
  removed `fable` from the aliases, and a different `advisorModel` changed the
  first line. The `--advisor` helper uses this as its preflight.

These are capability checks, not quality, speed, or cost rankings.

## Terra visual route check: 2026-10-27

The owner rendered an isolated synthetic PNG with two product cards. Panel A's
button extended beyond the card and clipped its label; panel B showed the full
button. Both cards displayed `24.00 EUR`. The worker received only the image
path and a read-only inspection brief, without the rendering source or expected
answer. No customer data or live application was involved.

A native Codex worker requested `gpt-6.1-terra` at `medium` with
`fork_turns: "none"`. Its saved `turn_context` confirmed the exact model and
effort, and its tool call used `view_image` on the assigned PNG. It returned:

- Panel A has the visible defect: the button and label are clipped at the right
  card edge; panel B shows `Continue to next step` in full.
- Both displayed prices are `24.00 EUR`.
- The evidence is static; button behavior, responsiveness, and the underlying
  cause remain unverified. No interaction was claimed.

The owner checked these observations against the image and known fixture,
validated the structured result, and confirmed the input remained byte-identical.
No rework was needed. This supports the bounded image-inspection route, without
establishing comparative quality, speed, cost, or live browser/desktop capability.

An earlier CLI attempt used Codex 0.164.0 with `--ignore-user-config`, the same
model/effort, and a read-only sandbox. Its startup and saved context confirmed
the requested settings, but model-metadata refresh and connection attempts timed
out; the run ended with `Incomplete response returned, reason: max_output_tokens`
and exit status 1 without a usable result. That failed transport/configuration
path is excluded from model-quality conclusions. The native success does not
establish an end-to-end CLI image hand-off on this machine.
