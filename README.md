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
| `.agents/AGENTS.md` | Canonical portable baseline installed globally. |
| `.agents/ORCHESTRATION.md` | Short task router that selects only relevant playbooks. |
| `.agents/rules/` | On-demand routing, review, execution, and setup guidance. |
| `scripts/install-global.sh` | Idempotent installer for Codex, Claude, and the review helpers. |
| `scripts/refresh-global-setup.sh` | Safe once-per-day fast-forward, test, and reinstall refresh. |
| `scripts/claude-review.sh` | Focused read-only Opus 5.5 or Fable 5.1 review hand-off. |
| `scripts/sol-review.sh` | Shared read-only Codex helper, installed as `sol-review` and `astra-review`. |
| `scripts/test.sh` | Isolated portability, installer, and dispatch regression tests. |

### Discovery and provider-specific folders

`.agents/` is the canonical source directory. The root `AGENTS.md` remains the
entry point because Codex discovers instructions at the repository root and
along the path to the working directory, not automatically inside `.agents/`.
See [Codex instruction discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md#how-codex-discovers-guidance).

The files in `.agents/rules/` are explicitly selected by `ORCHESTRATION.md`.
This is a repository convention for on-demand guidance, not a universal native
rules loader. Installing them in `.claude/rules/` would load unscoped rules at
startup and defeat that selective loading.
See [Claude rules](https://code.claude.com/docs/en/memory#organize-rules-with-clauderules).

Add other extension directories only when they contain a real extension:

| Extension | Native location and format |
| --- | --- |
| Codex skills | `.agents/skills/<name>/SKILL.md`, with `name` and `description` frontmatter; user skills belong in `~/.agents/skills/`. |
| Claude skills and prompt commands | `.claude/skills/<name>/SKILL.md`; `.claude/commands/*.md` remains supported for existing commands. |
| Claude subagents | `.claude/agents/*.md`, with Claude-specific frontmatter. |
| Claude rules | `.claude/rules/*.md` for instructions intended for Claude's native rule loading. |

See [Codex skills](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills),
[Claude skills](https://code.claude.com/docs/en/skills), and
[Claude subagents](https://code.claude.com/docs/en/sub-agents).
This repository currently ships instruction modules and executable shell
helpers, with no skill or subagent definitions. Helpers stay in `scripts/`;
renaming a shell script into `commands/` does not register a prompt command.

## Install globally

```sh
git clone https://github.com/JordyDutch/multi-provider-orchestration.git
cd multi-provider-orchestration
./scripts/install-global.sh
```

The installer:

- copies `.agents/AGENTS.md` to `~/.codex/AGENTS.md`;
- copies the router to `~/.codex/ORCHESTRATION.md` and rules to `~/.codex/rules/`;
- installs `claude-review`, `fable-review`, `sol-review`, `astra-review`, and
  `refresh-global-setup` under `~/.local/bin`;
- preserves existing `~/.claude/CLAUDE.md` content and adds exactly one
  `@~/.codex/AGENTS.md` import;
- backs up differing installed files and verifies every copy byte-for-byte.

After installation, Codex loads the compact global baseline and then only the
repository-specific root instructions. Claude loads the same global baseline
through its import. The root bootstrap detects the marker already present in the
instruction chain and does not ask either engine to read `.agents/AGENTS.md`
again.

If the repository has just been cloned and is not installed yet, root
`AGENTS.md` and `CLAUDE.md` direct both engines to the local shared baseline.
That keeps the GitHub repository usable without a prior machine-level setup.

If `~/.local/bin` is not on `PATH`, add it to the shell configuration.

Upgrades install the new router and `.agents/rules/` content together. An older
`~/.codex/playbooks/` directory is left intact for existing references; the new
router uses `~/.codex/rules/`. Differing baseline, router, and rule files are
backed up before replacement, and unrelated files are preserved.

The installed `rules/*.md` files are instruction modules selected by our router.
Codex also uses that directory for native command policies such as
`default.rules`, which use the separate Starlark `.rules` format. The installer
only copies the Markdown modules and preserves existing `.rules` files; it does
not change command permissions. See [Codex command rules](https://learn.chatgpt.com/docs/agent-configuration/rules).

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

Astra owns Codex orchestration; Fable owns Claude orchestration. Either owner
selects specialists across providers by task fit. The canonical
[model routing guide](.agents/rules/routing.md) contains model IDs, roles,
effort levels, escalation, access checks, and live sources. The baseline keeps
only the defaults needed for small tasks that do not load a playbook.

Codex routing uses Astra, Sol, and Luna, with Sol handling both everyday and
complex implementation and Luna handling mechanical work.

Choose a specialist after a cheap scope check only with a known scope,
sufficient capability, decisive checks, and expected net savings. Keep unclear
work with the strong owner; use the owner or shell for tiny deterministic work.
Set both the live-verified model and effort in the actual worker spawn, with
fresh compact context where supported. Naming Sol or Luna
in instructions does not change the runtime model. Consider Opus for
frontend/UX before authoring and return unexpected behavioral or security
questions to the owner. The owner integrates the result and final checks.

The [review guide](.agents/rules/reviews.md) determines whether a review is
needed and selects its provider and effort by authorship and risk. A change
spanning many files does not require review solely because of its size.

The installer adds instructions and helpers without changing `config.toml`,
existing tasks, or remote hosts. Routing is instruction-guided; there is no
automatic dispatcher or guaranteed cost saving. A smaller model can still use
more tokens if it receives excess context or causes repeated work.

## Task completion

The shared baseline calls for completing the authorized outcome, including
verification and fixing defects caused by the change. Routine local steps use
existing authorization. Missing information that materially affects the result
or work outside the authorized scope still calls for user input; Git permissions
and the daily refresh gate remain explicit boundaries.

Required checks still run. After they pass, additional checks need a reason:
new changes, failures, or unresolved risk. This keeps verification proportionate
while preserving the separate review requirements.

This layout follows the contextual guidance and completion principles in
[OpenAI's skills and prompts article](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra).

## Vendor into one repository

Copy the bootstrap plus the entire `.agents` directory so the destination remains
self-contained:

```sh
cp AGENTS.md CLAUDE.md ORCHESTRATION.md /path/to/repo/
mkdir -p /path/to/repo/.agents
cp -R .agents/. /path/to/repo/.agents/
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

`claude-review` pins `claude-opus-5-5` at `high` effort. Older Opus IDs and
unpinned aliases are rejected. `fable-review` keeps `claude-fable-5-1` at `xhigh`.
The exact Opus ID follows [Anthropic's migration guide](https://platform.claude.com/docs/en/models/opus-5-5/migration-guide).
Opus 5.5 requires Claude Code 2.1.280 or newer. Run `claude update` before using
the helper if your CLI is older.

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
`gpt-6-sol` at xhigh for normal and complex Claude-code reviews. It reads only
`SOL_REVIEW_*`; `SOL_REVIEW_MODEL` must be `gpt-6-sol` when set. To request
Astra, call `astra-review` explicitly; a Sol model override can no longer select
another model. Both helpers retain the calling orchestrator as owner.
Both Codex routes reject unknown executable names and efforts outside
low/medium/high/xhigh/max; `ultra` is not allowed in review hand-offs.

Run Claude helpers outside the Codex filesystem/process sandbox. They preflight
authentication themselves, so a separate `claude auth status` immediately before
the review is unnecessary. A sandbox-only `loggedIn: false` must be rechecked in
host context before asking the user to sign in. Claude's final text is buffered;
silence while its process lives is not a hang and must not trigger a duplicate.

Use the [review guide](.agents/rules/reviews.md) to decide when these helpers
are needed and which route fits the change. Helper availability alone does not
require a review.

## Verify changes

```sh
./scripts/test.sh
git diff --check
```

Model names, access, and effort levels are volatile. Recheck the official sources
and compact live CLI catalogs before changing pinned routes.
