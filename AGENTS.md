# Repository bootstrap

This repository keeps its portable, installable agent baseline under
`.agents/`.

- Unless an earlier higher-level instruction explicitly states that the MPO
  shared baseline is already active, read `.agents/AGENTS.md` before planning,
  editing, or delegating. This makes a fresh clone self-contained before the
  global installer runs.
- If that earlier instruction says the baseline is active, do not reload the
  local copy. This avoids sending the same portable rules twice.
- For substantial, risky, multi-provider, or multi-agent work, follow the
  router adjacent to the active baseline: `.agents/ORCHESTRATION.md` in a fresh
  clone or `~/.codex/ORCHESTRATION.md` after global installation.

## This repo

- Root `AGENTS.md` is only the clone bootstrap. The canonical portable baseline
  is `.agents/AGENTS.md`; the installer copies that file globally.
- Keep detailed routing in `.agents/rules/`, with each rule defined in one
  module and linked from `.agents/ORCHESTRATION.md`.
- Changes to routing, installation, or review helpers require
  `./scripts/test.sh` and `git diff --check`.
- Update `README.md` whenever installation steps or public helper behavior
  changes.
