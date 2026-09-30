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
