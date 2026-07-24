#!/bin/sh

set -eu

model="${SOL_REVIEW_MODEL:-gpt-5.6-sol}"
effort="${SOL_REVIEW_EFFORT:-high}"
prompt="${*:-Review the current change adversarially for concrete bugs, regressions, and missing tests. Return findings ordered by severity with file and line evidence. Do not edit files.}"
role_preamble="You are a bounded independent reviewer in a Fable-led workflow. Fable retains final integration and synthesis ownership. Do not edit files, widen the task, or claim final ownership."

codex_bin="$(command -v codex 2>/dev/null || true)"
if [ -z "$codex_bin" ] && [ -x "$HOME/.local/bin/codex" ]; then
  codex_bin="$HOME/.local/bin/codex"
fi

if [ -z "$codex_bin" ]; then
  echo "Sol review unavailable: the codex CLI is not on PATH." >&2
  echo "Install Codex, then run: codex login" >&2
  exit 127
fi

if ! "$codex_bin" login status >/dev/null 2>&1; then
  echo "Sol review unavailable: Codex is not authenticated." >&2
  echo "Run: $codex_bin login" >&2
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Sol review unavailable: the current directory is not a Git worktree." >&2
  exit 3
fi

echo "Running read-only Sol review with $model at $effort effort..." >&2

{
  printf '%s\n\n' "$role_preamble"
  printf '%s\n\n' "$prompt"
  printf '%s\n' \
    "The repository evidence below was captured by the read-only wrapper." \
    "Untracked paths appear in status but not in Git diffs; inspect them read-only." \
    "Do not edit files." \
    "" \
    "=== git status --short --branch ==="
  git status --short --branch
  printf '%s\n' "" "=== unstaged diff ==="
  git --no-pager diff --no-ext-diff --
  printf '%s\n' "" "=== staged diff ==="
  git --no-pager diff --cached --no-ext-diff --
} | "$codex_bin" exec \
    --model "$model" \
    --config "model_reasoning_effort=\"$effort\"" \
    --sandbox read-only \
    --ephemeral \
    -
