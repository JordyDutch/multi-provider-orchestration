# Installation and setup

Read this guide for global installation, daily refresh, portable repository use,
or setup troubleshooting.

## Global installation

From the cloned checkout, run:

```sh
./scripts/install-global.sh
```

The installer copies the canonical baseline and router from `shared/` into
`~/.codex`, copies `shared/playbooks/` into `~/.codex/playbooks/`, installs the
review and refresh helpers under `~/.local/bin`, and adds exactly one
`@~/.codex/AGENTS.md` import to `~/.claude/CLAUDE.md`. It preserves existing
Claude-only instructions, backs up differing installed files, and verifies all
copies byte-for-byte.

The root `AGENTS.md` remains a small repository bootstrap. A fresh clone that has
not been installed reads `shared/AGENTS.md`; an installed session already
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
bootstrap files, the complete `shared/` directory, and optional local helpers:

```sh
cp AGENTS.md CLAUDE.md ORCHESTRATION.md /path/to/repo/
cp -R shared /path/to/repo/shared
mkdir -p /path/to/repo/scripts
cp scripts/claude-review.sh scripts/sol-review.sh /path/to/repo/scripts/
cp scripts/sol-review.sh /path/to/repo/scripts/astra-review
chmod +x /path/to/repo/scripts/claude-review.sh \
  /path/to/repo/scripts/sol-review.sh /path/to/repo/scripts/astra-review
```

Add repository-specific rules under `## This repo` in the destination root
`AGENTS.md`. Never replace unrelated user instructions during installation.

## Defaults

A general Codex default remains:

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
```

Use Astra explicitly for the hardest or critical work after checking client
access, with `high` as the starting effort (`xhigh` for a decisive hard stage):

```sh
codex --model gpt-6-astra -c 'model_reasoning_effort="high"'
```

The installer adds `astra-review` alongside `sol-review`; it does not change
`config.toml`, existing tasks, or other machines. Use Terra and Luna for bounded
work. Routing instructions guide selection; they are not an automatic dispatcher.
