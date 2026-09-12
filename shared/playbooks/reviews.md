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
decisive tests or factual lookups directly supported by primary sources.
Ambiguity, weak verification, or broad behavioral impact can still make a
review necessary. Do not use a vague `substantial` label as the only trigger.

## Review routes

| Authorship and risk | Reviewer |
| --- | --- |
| Normal bounded Codex-authored behavior | Opus 5 (`claude-opus-5`) at high |
| Complex or cross-cutting Codex-authored work | Fable 5.1 (`claude-fable-5-1`) at xhigh |
| Normal bounded Claude-authored behavior | Sol at xhigh |
| Complex or cross-cutting Claude-authored work | Sol at xhigh |
| Exceptionally hard, unresolved, or critical Claude-authored work | Astra (`gpt-6-astra`) at xhigh; max only for the hardest unresolved judgement |
| Critical Codex-authored work | Fable 5.1 at xhigh; add Opus 5 at high only when a second Claude perspective materially reduces risk |

These risk-based routes follow the implementation author, not the orchestrator.
Under Astra, Claude-written code gets an independent Sol review; Codex-written
code gets Claude review. For mixed authorship, review each scope across providers;
use an independent reviewer session, including when the owner wrote that scope.
Complexity alone does not bypass Sol. Escalate only for concrete unresolved
questions or critical consequences; the owner retains final integration.
If Astra cannot review the change, report it; use Sol xhigh/max once if adequate.
Otherwise stop the affected scope. Helpers never automatically downgrade.

## Claude helpers from Codex

Run `claude-review` and `fable-review` in host context for access to Claude's
credential store. Helpers preflight authentication; do not duplicate checks.
Recheck a sandbox-only `loggedIn: false` in host context before asking the user
to sign in again; the host result is authoritative.

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

The wrapper rejects absolute paths and traversal. It pins Opus 5/high or
Fable 5.1/xhigh, allows only `Read`, `Grep`, `Glob`, disables unrelated MCP and
slash-command context, and separates dynamic context from the cache prefix.
Older CLIs retain allow/deny lists and report unsupported optimizations.

Helpers cap diff plus status at 200,000 bytes. Scope first; raise the matching
`*_REVIEW_MAX_DIFF_BYTES` only when the complete larger diff is required.

Override effort explicitly when the risk table requires a stronger route:

```sh
CLAUDE_REVIEW_EFFORT=xhigh claude-review \
  "Review this unusually subtle security boundary."
ASTRA_REVIEW_EFFORT=xhigh astra-review \
  "Review this critical Claude-authored auth change."
```

Claude output is buffered; poll the same live process, never a duplicate. After
a bounded timeout, terminate cleanly and retry Opus 5 once at medium with the exact diff
and repository tools disabled. If that retry fails, use Fable 5.1 once and
report the fallback; never substitute an older Opus model.

## Codex helpers from Claude

`sol-review` pins `gpt-5.6-sol` at xhigh; `astra-review` pins `gpt-6-astra`
at high (request xhigh for an exceptional review). Both use ephemeral read-only
sessions and keep the calling orchestrator as owner, including Astra when
reviewing Claude contributions. The shared script dispatches by executable name.
Each reads only its matching `SOL_REVIEW_*` or `ASTRA_REVIEW_*` settings; model
overrides must match that helper's exact model. Failure never triggers fallback.
Unknown names and efforts outside low/medium/high/xhigh/max fail closed.

```sh
sol-review "Review the current change for concrete defects and missing tests."
SOL_REVIEW_MODE=audit sol-review "Audit only the named repository paths."
SOL_REVIEW_DIFF_PATH=src/auth sol-review "Review only this path."
ASTRA_REVIEW_EFFORT=xhigh astra-review "Review this critical Claude-authored change."
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
