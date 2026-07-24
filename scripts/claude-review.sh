#!/bin/sh

set -eu

case "$(basename "$0")" in
  fable-review)
    default_model="claude-fable-5"
    ;;
  *)
    default_model="claude-opus-4-8"
    ;;
esac

model="${CLAUDE_REVIEW_MODEL:-$default_model}"
effort="${CLAUDE_REVIEW_EFFORT:-high}"
prompt="${*:-Review the current change adversarially for concrete bugs, regressions, and missing tests. Return findings ordered by severity with file and line evidence. Do not edit files.}"

if [ "$model" = "claude-fable-5" ]; then
  role_preamble="You are a bounded independent reviewer in a Sol-led workflow. Sol retains final integration and synthesis ownership. Do not widen the task or claim final ownership."
else
  role_preamble="You are a bounded independent Claude reviewer. The calling orchestrator retains final integration and synthesis ownership. Do not widen the task or claim final ownership."
fi

claude_bin="$(command -v claude 2>/dev/null || true)"
if [ -z "$claude_bin" ] && [ -x "$HOME/.local/bin/claude" ]; then
  claude_bin="$HOME/.local/bin/claude"
fi

if [ -z "$claude_bin" ]; then
  echo "Claude review unavailable: the claude CLI is not on PATH." >&2
  echo "Install Claude Code, then run: claude auth login" >&2
  exit 127
fi

auth_status="$("$claude_bin" auth status 2>&1 || true)"
if ! printf '%s\n' "$auth_status" | grep -q '"loggedIn"[[:space:]]*:[[:space:]]*true'; then
  echo "Claude review unavailable: Claude Code is not authenticated." >&2
  echo "Run: $claude_bin auth login" >&2
  printf '%s\n' "$auth_status" >&2
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Claude review unavailable: the current directory is not a Git worktree." >&2
  exit 3
fi

echo "Running read-only Claude review with $model at $effort effort..." >&2

{
  printf '%s\n\n' "$role_preamble"
  printf '%s\n\n' "$prompt"
  printf '%s\n' \
    "The repository evidence below was captured by the read-only wrapper." \
    "Untracked paths appear in status but not in Git diffs; inspect them with Read or Glob." \
    "You may use Read, Grep, and Glob for more context. Do not edit files." \
    "" \
    "=== git status --short --branch ==="
  git status --short --branch
  printf '%s\n' "" "=== unstaged diff ==="
  git --no-pager diff --no-ext-diff --
  printf '%s\n' "" "=== staged diff ==="
  git --no-pager diff --cached --no-ext-diff --
} | "$claude_bin" \
    --print \
    --model "$model" \
    --effort "$effort" \
    --permission-mode dontAsk \
    --allowedTools "Read" "Grep" "Glob" \
    --disallowedTools "Bash" "Edit" "Write" "NotebookEdit" \
    --output-format text
