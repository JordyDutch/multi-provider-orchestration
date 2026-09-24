# Installation and setup

Read this guide for global installation, daily refresh, portable repository use,
or setup troubleshooting.

## Global installation

From the cloned checkout, run:

```sh
./scripts/install-global.sh
```

The installer copies the canonical baseline and router from `.agents/` into
`~/.codex`, copies `.agents/rules/` into `~/.codex/rules/`, installs the
review and refresh helpers under `~/.local/bin`, and adds exactly one
`@~/.codex/AGENTS.md` import to `~/.claude/CLAUDE.md`. It preserves existing
Claude-only instructions, backs up differing installed files, and verifies all
copies byte-for-byte.

Older `~/.codex/playbooks/` files are preserved for existing references. The new
router selects `~/.codex/rules/`; unrelated installed files remain untouched.
These `*.md` instruction modules are distinct from Codex's native `*.rules`
command policies in the same directory. Existing command policies, including
`default.rules`, are preserved; installation does not change command permissions.

The root `AGENTS.md` remains a small repository bootstrap. A fresh clone that has
not been installed reads `.agents/AGENTS.md`; an installed session already
contains its marker and does not reread it. This preserves clone portability
without loading the full baseline twice.

## Daily refresh

Before the first non-trivial code, configuration, or documentation edit each
local day, run:

```sh
refresh-global-setup
```

The helper accepts only the canonical GitHub origin, a clean fast-forward to
`origin/main`, passing tests, and a verified reinstall before writing its daily
success stamp. Dirty, divergent, missing, or failing checkouts are safe blockers;
never overwrite them automatically.

## Portable repository copy

To vendor this setup without requiring a prior global install, copy the root
bootstrap files, the complete `.agents/` directory, and optional local helpers:

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

Add repository-specific rules under `## This repo` in the destination root
`AGENTS.md`. Never replace unrelated user instructions during installation.

## Defaults

For Codex-led orchestration, use Astra as the entry owner after verifying access:

```toml
model = "gpt-6-astra"
model_reasoning_effort = "high"
```

Use `high` normally and `xhigh` for a decisive hard stage. To select the owner
for one session:

```sh
codex --model gpt-6-astra -c 'model_reasoning_effort="high"'
```

Sol handles bounded and complex execution and regular reviews. Fable owns
Claude-led sessions; use Opus for frontend/UX or implementation by fit, verified
Sonnet for mechanical Claude work, and Luna for mechanical Codex work.

The installer adds `astra-review` alongside `sol-review`; it does not change
`config.toml`, existing tasks, or other machines. The model picker or explicit
CLI model selects the entry session. For a worker, select its live-verified
model and effort in the actual spawn; instructions alone cannot switch models.
There is no automatic dispatch or cost guarantee. Smaller models may use more
tokens if context or repeated work grows; keep hand-offs compact.
