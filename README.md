# Multi-provider orchestration

A portable, provider-neutral setup for combining OpenAI Codex and Claude Code
with risk-based model routing, focused opposite-provider review, bounded
parallelism, and verified global installation.

The layout avoids loading the full baseline twice while remaining self-contained
for people who clone the repository before installing it.

## Layout

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Small clone bootstrap; tells an uninstalled agent where to find the portable baseline. |
| `CLAUDE.md` | Thin Claude entry point that imports the bootstrap. |
| `ORCHESTRATION.md` | Compatibility pointer for older links and copies. |
| `shared/AGENTS.md` | Canonical portable baseline installed globally. |
| `shared/ORCHESTRATION.md` | Short task router that selects only relevant playbooks. |
| `shared/playbooks/` | On-demand routing, review, execution, and setup guidance. |
| `scripts/install-global.sh` | Idempotent installer for Codex, Claude, and the review helpers. |
| `scripts/refresh-global-setup.sh` | Safe once-per-day fast-forward, test, and reinstall refresh. |
| `scripts/claude-review.sh` | Focused read-only Opus 5 or Fable 5.1 review hand-off. |
| `scripts/sol-review.sh` | Shared read-only Codex helper, installed as `sol-review` and `astra-review`. |
| `scripts/test.sh` | Isolated portability, installer, and dispatch regression tests. |

## Install globally

```sh
git clone https://github.com/JordyDutch/multi-provider-orchestration.git
cd multi-provider-orchestration
./scripts/install-global.sh
```

The installer:

- copies `shared/AGENTS.md` to `~/.codex/AGENTS.md`;
- copies the shared router and playbooks to `~/.codex`;
- installs `claude-review`, `fable-review`, `sol-review`, `astra-review`, and
  `refresh-global-setup` under `~/.local/bin`;
- preserves existing `~/.claude/CLAUDE.md` content and adds exactly one
  `@~/.codex/AGENTS.md` import;
- backs up differing installed files and verifies every copy byte-for-byte.

After installation, Codex loads the compact global baseline and then only the
repository-specific root instructions. Claude loads the same global baseline
through its import. The root bootstrap detects the marker already present in the
instruction chain and does not ask either engine to read `shared/AGENTS.md`
again.

If the repository has just been cloned and is not installed yet, root
`AGENTS.md` and `CLAUDE.md` direct both engines to the local shared baseline.
That keeps the GitHub repository usable without a prior machine-level setup.

If `~/.local/bin` is not on `PATH`, add it to the shell configuration.

## Daily refresh

Before the first non-trivial coding, configuration, or documentation change each
day, the installed agent runs:

```sh
refresh-global-setup
```

The helper accepts only the canonical GitHub origin, a clean fast-forward to
`origin/main`, passing tests, and a verified reinstall. Dirty, divergent,
missing, or failing checkouts stop safely without overwriting user work.

## Model and reasoning routes

Choose the route at the task boundary and use the lowest reasoning effort that
meets the confidence requirement:

| Task shape | Route |
| --- | --- |
| One clear extraction, classification, formatting, transformation, or mechanical pass | Luna (`gpt-5.6-luna`) at `low` |
| Still-mechanical work spanning several items or checks | Luna at `medium` |
| Normal scoped repository analysis, implementation, or tests | Terra (`gpt-5.6-terra`) at `medium` |
| Bounded multi-file work with real tradeoffs | Terra at `high` |
| Complex execution, planning support, design analysis, or diagnosis | Sol (`gpt-5.6-sol`) at `high` |
| Codex orchestration: planning, task allocation, integration, and final judgement | Astra (`gpt-6-astra`) at `high`; `xhigh` for the decisive hard stage |
| Critical decisions involving security, funds, data loss, or costly architecture | Astra at `xhigh`; `max` only for the hardest unresolved single-agent judgement |
| Claude orchestration and complex Claude implementation or analysis | Fable 5.1 (`claude-fable-5-1`) at `high` |
| Frontend/UX and substantive Claude implementation | Prefer Opus 5 (`claude-opus-5`) at `high` |
| Mechanical Claude tasks where a hand-off is useful | Sonnet 5 (`claude-sonnet-5`) at `low`/`medium`, after live access verification |

Prefer a stronger model when the task changes class instead of indefinitely
raising effort on Luna or Terra. Here, bounded means a named scope, known success
criteria and verification, and no unresolved architecture or cross-cutting
integration; ambiguity promotes execution to Sol or Fable for analysis, while
the calling owner decides and integrates. A strong active owner may finish a
tiny scope directly when a hand-off would cost more than it saves.

Astra owns Codex orchestration; Fable owns Claude orchestration. Either owner
selects specialists across providers by task fit. Sol remains a primary complex
executor and reviewer; Claude also implements, designs, and analyzes. Ownership
does not require the owner to write every patch or review its own work. Review
provider follows the implementation author; full rules live in `shared/playbooks/`.

Verify access on the current client; catalog presence alone does not prove
entitlement. If Astra cannot own the task,
report it and use Sol high/xhigh once only when adequate; otherwise stop the
affected scope. The installer adds routing instructions and helpers, without changing
`config.toml`, existing tasks, or remote hosts. These instructions guide model
selection; there is no automatic dispatcher.

Roles and efforts are repository workflow choices. Check current model details
in the [OpenAI documentation](https://learn.chatgpt.com/docs/models) and
[Claude documentation](https://platform.claude.com/docs/en/about-claude/pricing).

## Vendor into one repository

Copy the bootstrap plus the entire shared directory so the destination remains
self-contained:

```sh
cp AGENTS.md CLAUDE.md ORCHESTRATION.md /path/to/repo/
cp -R shared /path/to/repo/shared
mkdir -p /path/to/repo/scripts
cp scripts/claude-review.sh scripts/sol-review.sh /path/to/repo/scripts/
cp scripts/sol-review.sh /path/to/repo/scripts/astra-review
chmod +x /path/to/repo/scripts/claude-review.sh \
  /path/to/repo/scripts/sol-review.sh /path/to/repo/scripts/astra-review
```

Add stack, architecture, conventions, and exact verification commands under
`## This repo` in the copied root `AGENTS.md`.

Older repositories that contain a complete historical baseline in their root
`AGENTS.md` continue to work, but will still load that copy after the global
baseline. Migrate them to the small bootstrap layout when convenient; the global
installer never rewrites arbitrary repositories.

## Focused reviews

A normal review fails closed only when its selected scope has no tracked or
untracked changes:

```sh
claude-review "Review the changed behavior and missing tests."
fable-review "Review this cross-cutting change."
sol-review "Review the changed behavior and missing tests."
ASTRA_REVIEW_EFFORT=xhigh astra-review "Review this critical Claude-authored change."
```

For an intentional clean-tree audit, opt in explicitly:

```sh
CLAUDE_REVIEW_MODE=audit claude-review "Audit only the named files."
SOL_REVIEW_MODE=audit sol-review "Audit only the named files."
ASTRA_REVIEW_MODE=audit astra-review "Audit only the named files."
```

Limit evidence to one relative file or directory when unrelated work exists:

```sh
CLAUDE_REVIEW_DIFF_PATH=src/auth claude-review "Review this path only."
SOL_REVIEW_DIFF_PATH=src/auth sol-review "Review this path only."
ASTRA_REVIEW_DIFF_PATH=src/auth astra-review "Review this path only."
```

The Claude wrapper sends one combined `git diff HEAD` (or both the staged diff
and current working-copy delta before the first commit) and lists untracked paths
for read-only inspection. On current Claude CLIs it exposes only `Read`, `Grep`,
and `Glob`, disables unrelated MCP and slash-command context, and asks Claude to
move per-machine system sections outside the stable prompt-cache prefix. Older
CLIs retain explicit allow/deny lists and print notices for unavailable context
optimizations. Both wrappers reject absolute paths and parent traversal, and
fail before a model call when diff-plus-status evidence exceeds 200,000 bytes.
Prefer a path scope; raise
`CLAUDE_REVIEW_MAX_DIFF_BYTES`, `SOL_REVIEW_MAX_DIFF_BYTES`, or
`ASTRA_REVIEW_MAX_DIFF_BYTES` only explicitly. `astra-review` pins `gpt-6-astra`
at high and reads only `ASTRA_REVIEW_*` settings; it never automatically falls
back to Sol. Use `ASTRA_REVIEW_EFFORT=xhigh` for critical Claude-authored work,
or `max` only for the hardest unresolved judgement. `sol-review` pins
`gpt-5.6-sol` at xhigh for normal and complex Claude-code reviews. It reads only
`SOL_REVIEW_*`; `SOL_REVIEW_MODEL` must be `gpt-5.6-sol` when set. To request
Astra, call `astra-review` explicitly; a Sol model override can no longer select
another model. Both helpers retain the calling orchestrator as owner.
Both Codex routes reject unknown executable names and efforts outside
low/medium/high/xhigh/max; `ultra` is not allowed in review hand-offs.

Run Claude helpers outside the Codex filesystem/process sandbox. They preflight
authentication themselves, so a separate `claude auth status` immediately before
the review is unnecessary. A sandbox-only `loggedIn: false` must be rechecked in
host context before asking the user to sign in. Claude's final text is buffered;
silence while its process lives is not a hang and must not trigger a duplicate.

Review strength is based on consequence and uncertainty, not an automatic
one-tier surcharge. Normal Codex-authored behavioral work uses Opus 5 at high;
complex Codex-authored work uses Fable 5.1 at xhigh; normal and complex
Claude-authored work uses Sol at xhigh. Reserve Astra reviews for exceptionally
hard, unresolved, or critical Claude work. This applies under either owner;
mixed contributions need independent review across providers for each scope.
Deterministic work with decisive verification and primary-source-backed factual
lookups may remain single-provider.

## Verify changes

```sh
./scripts/test.sh
git diff --check
```

Model names, access, and effort levels are volatile. Recheck the official sources
and compact live CLI catalogs before changing pinned routes.
