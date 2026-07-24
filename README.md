# Multi-provider orchestration

A portable, provider-neutral setup for combining OpenAI Codex and Claude Code
in software projects. It defines strong orchestrator and worker routes,
opposite-provider review, bounded delegation, verification requirements, and a
reliable read-only Claude review hand-off from Codex.

## Included

| File | Purpose |
| --- | --- |
| `AGENTS.md` | Shared global and per-repo rules read natively by Codex and imported by Claude. |
| `CLAUDE.md` | Thin Claude Code entry point that imports `AGENTS.md`. |
| `ORCHESTRATION.md` | Full model-routing, effort, delegation, review, and verification playbook. |
| `scripts/install-global.sh` | Idempotent global installer for both Codex and Claude. |
| `scripts/claude-review.sh` | Read-only Opus or Fable review hand-off for Codex-led work. |
| `scripts/sol-review.sh` | Symmetric read-only Sol review hand-off for Fable-led work. |
| `scripts/test.sh` | Isolated installer and model-dispatch regression tests. |

## Install globally

Clone the repository and run the installer:

```sh
git clone https://github.com/JordyDutch/multi-provider-orchestration.git
cd multi-provider-orchestration
./scripts/install-global.sh
```

The installer:

- copies `AGENTS.md` and `ORCHESTRATION.md` into `~/.codex`;
- installs `claude-review`, `fable-review`, and `sol-review` into
  `~/.local/bin`;
- preserves existing `~/.claude/CLAUDE.md` content;
- adds `@~/.codex/AGENTS.md` to Claude's rules exactly once;
- backs up differing global Codex context files before replacing them;
- verifies every installed copy byte-for-byte.

This makes the same orchestration rules available to Codex and Claude in every
user repository. Installing this baseline replaces the existing global
`~/.codex/AGENTS.md`; project-level `AGENTS.md` files can still add or override
repo-specific rules.

You can also ask either model to install the checked-out setup globally. The
rules explicitly require the model to run `./scripts/install-global.sh`, preserve
existing Claude-only instructions, and verify the resulting local files instead
of merely describing the setup.

If `~/.local/bin` is not on `PATH`, add it to your shell configuration.

## Use in one repository

Copy the shared files into a repository:

```sh
cp AGENTS.md CLAUDE.md ORCHESTRATION.md /path/to/repo/
mkdir -p /path/to/repo/scripts
cp scripts/claude-review.sh scripts/sol-review.sh /path/to/repo/scripts/
chmod +x /path/to/repo/scripts/claude-review.sh \
  /path/to/repo/scripts/sol-review.sh
```

Add stack, architecture, conventions, and exact verification commands under
`## This repo` in the copied `AGENTS.md`.

## Claude review from Codex

After the global install, run this from any Git worktree:

```sh
claude-review
```

The helper checks the Claude CLI and authentication, captures staged and
unstaged diffs with read-only Git commands, pins Opus at high effort by default,
and gives Claude only `Read`, `Grep`, and `Glob`.

For complex code, architecture, multi-workstream, or conflicting-findings review
inside a Sol-led workflow, call Fable through the same read-only wrapper:

```sh
fable-review \
  "Review the current change for cross-cutting code and architecture defects."
```

Sol remains the owning orchestrator and validates and integrates Fable's
findings. Likewise, a Fable-led workflow can use Sol as a bounded complex
reviewer without transferring final ownership.

```sh
sol-review \
  "Review the current change for cross-cutting code and architecture defects."
```

`sol-review` captures the diff, pins GPT-5.6 Sol at high effort, and enforces the
Codex `read-only` sandbox. If a requested Fable route is unavailable, fall back
once to `claude-review` and report that Fable review was skipped.

Override the route only after verifying model availability:

```sh
CLAUDE_REVIEW_MODEL=claude-opus-4-8 \
CLAUDE_REVIEW_EFFORT=xhigh \
  claude-review "Review this security-sensitive change."
```

## Verify changes

```sh
./scripts/test.sh
```

Model names, access, and effort levels can change. Recheck the live CLI
catalogs before updating pinned routes.
