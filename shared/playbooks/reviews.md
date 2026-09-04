# Independent reviews

Read this guide for opposite-provider reviews, clean-tree audits, review helper
behavior, or review recovery.

## When review is required

Require a strong opposite-provider review for security boundaries,
authentication, authorization, permissions, funds or signing, destructive
changes, data-loss risk, migrations, production infrastructure, costly-to-reverse
architecture, unfamiliar behavioral changes, repeated failed diagnosis, or
conflicting evidence.

A second provider is normally unnecessary for deterministic changes with
decisive tests or factual lookups directly supported by primary sources. Scale,
ambiguity, weak verification, or meaningful behavioral impact can still make a
review necessary. Do not use a vague `substantial` label as the only trigger.

## Review routes

| Authorship and risk | Reviewer |
| --- | --- |
| Normal bounded Codex-authored behavior | Opus 5 (`claude-opus-5`) at high |
| Complex or cross-cutting Codex-authored work | Fable 5.1 (`claude-fable-5-1`) at xhigh |
| Normal bounded Claude-authored behavior | Sol at xhigh |
| Complex or cross-cutting Claude-authored work | Astra (`gpt-6-astra`) at high |
| Critical Claude-authored work | Astra at xhigh; max only for the hardest unresolved judgement |
| Critical Codex-authored work | Fable 5.1 at xhigh; add Opus 5 at high only when a second Claude perspective materially reduces risk |

These are risk-based routes, not an automatic one-rung surcharge. The owner may
escalate from concrete evidence and retains final integration responsibility.
If Astra cannot review the change, report it; use Sol xhigh/max once if adequate.
Otherwise stop the affected scope. Helpers never automatically downgrade.

## Claude helpers from Codex

Run `claude-review` and `fable-review` outside the Codex filesystem/process
sandbox so they can see the host Claude credential store. The wrappers preflight
the binary and authentication; do not run redundant checks unless a helper fails.
A sandbox-only `loggedIn: false` is not an authentication failure: rerun the
check or helper in host context, treat that result as authoritative, and do not
ask the user to sign in again unless the host check also fails.

```sh
claude-review "Review the affected behavior for concrete defects and missing tests."
fable-review "Review this cross-cutting change for architecture defects."
```

The default mode reviews tracked changes against `HEAD` as one combined diff and
lists untracked paths for inspection. Before a repository's first commit it
includes both the staged diff and the current working-copy delta, so edits made
after staging are not missed. It fails closed only when the selected scope
contains no tracked or untracked changes. For a clean-tree audit:

```sh
CLAUDE_REVIEW_MODE=audit claude-review \
  "Audit only the named files and return evidence-backed findings."
```

Limit a diff review to one relative file or directory when the worktree contains
unrelated changes:

```sh
CLAUDE_REVIEW_DIFF_PATH=src/auth claude-review \
  "Review only the authentication changes."
```

The wrapper rejects absolute paths and parent traversal. It pins Opus 5 at high
or Fable 5.1 at xhigh. On current Claude CLIs it exposes only `Read`, `Grep`, and
`Glob`, disables unrelated MCP and slash-command context, and asks Claude to move
dynamic system sections out of the stable cache prefix. On an older CLI it
retains the explicit allow/deny lists and prints a notice for each unavailable
context optimization.

Both review helpers fail before a model call when their diff plus status evidence
exceeds 200,000 bytes. Scope the review path first; only then explicitly raise
`CLAUDE_REVIEW_MAX_DIFF_BYTES`, `SOL_REVIEW_MAX_DIFF_BYTES`, or
`ASTRA_REVIEW_MAX_DIFF_BYTES` when the complete
larger diff is genuinely required.

Override effort explicitly when the risk table requires a stronger route:

```sh
CLAUDE_REVIEW_EFFORT=xhigh claude-review \
  "Review this unusually subtle security boundary."
ASTRA_REVIEW_EFFORT=xhigh astra-review \
  "Review this critical Claude-authored auth change."
```

Claude text output is buffered. No stdout while the process lives is not a hang:
poll the same process and never launch a duplicate. After a genuine bounded
timeout, terminate cleanly and retry Opus 5 once at medium with the exact diff
and repository tools disabled. If that retry fails, use Fable 5.1 once and
report the fallback; never substitute an older Opus model.

## Codex helpers from Claude

`sol-review` defaults to Sol at xhigh; `astra-review` pins exact `gpt-6-astra`
at high. Both use an ephemeral read-only Codex session and keep the calling
Claude orchestrator as owner. One shared script selects the route by executable
name. Astra reads only `ASTRA_REVIEW_*`; existing `SOL_REVIEW_*` settings cannot
silently redirect it. A model-call failure returns failure without a fallback.
Unknown executable names and efforts outside low/medium/high/xhigh/max fail
closed; `ultra` is not allowed in review hand-offs.

```sh
sol-review "Review the current change for concrete defects and missing tests."
SOL_REVIEW_MODE=audit sol-review "Audit only the named repository paths."
SOL_REVIEW_DIFF_PATH=src/auth sol-review "Review only this path."
astra-review "Review this complex Claude-authored change."
ASTRA_REVIEW_MODE=audit astra-review "Audit only the named repository paths."
ASTRA_REVIEW_DIFF_PATH=src/auth astra-review "Review only this path."
```

## Evidence contract

- Verify locally before review when possible.
- Send the goal, constraints, smallest relevant diff or named audit paths, exact
  failures, and concise verification evidence.
- Never send credentials, private keys, personal data, or unrelated changes.
- Ask for findings ordered by severity with file/line evidence, impact, and
  missing-test assessment.
- The owner validates every finding, makes corrections, and reruns affected
  checks. A reviewer does not take ownership by returning an opinion.
