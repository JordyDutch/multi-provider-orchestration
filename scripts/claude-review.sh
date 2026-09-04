#!/bin/sh

set -eu

case "$(basename "$0")" in
  fable-review)
    default_model="claude-fable-5-1"
    ;;
  *)
    default_model="claude-opus-5"
    ;;
esac

model="${CLAUDE_REVIEW_MODEL:-$default_model}"
prompt="${*:-Review the current change adversarially for concrete bugs, regressions, and missing tests. Return findings ordered by severity with file and line evidence. Do not edit files.}"
review_mode="${CLAUDE_REVIEW_MODE:-review}"
diff_path="${CLAUDE_REVIEW_DIFF_PATH:-}"
max_diff_bytes="${CLAUDE_REVIEW_MAX_DIFF_BYTES:-200000}"

case "$model" in
  claude-opus-5)
    default_effort="high"
    ;;
  claude-fable-5-1)
    default_effort="xhigh"
    ;;
  *)
    echo "Claude review unavailable: model must be pinned to claude-opus-5 or claude-fable-5-1." >&2
    exit 64
    ;;
esac

effort="${CLAUDE_REVIEW_EFFORT:-$default_effort}"

case "$review_mode" in
  review|audit)
    ;;
  *)
    echo "Claude review unavailable: CLAUDE_REVIEW_MODE must be review or audit." >&2
    exit 64
    ;;
esac

if [ -n "$diff_path" ]; then
  case "$diff_path" in
    /*|..|../*|*/..|*/../*)
      echo "Claude review unavailable: CLAUDE_REVIEW_DIFF_PATH must be a relative path without parent traversal." >&2
      exit 64
      ;;
  esac
fi

case "$max_diff_bytes" in
  ''|*[!0-9]*|0)
    echo "Claude review unavailable: CLAUDE_REVIEW_MAX_DIFF_BYTES must be a positive integer." >&2
    exit 64
    ;;
esac

role_preamble="You are a bounded independent Claude reviewer. The calling orchestrator retains final integration and synthesis ownership. Use the supplied diff as primary evidence, inspect only the smallest additional repository context needed, return a final verdict promptly, and do not widen the task or claim final ownership."

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

review_tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/claude-review.XXXXXX")"
diff_file="$review_tmp_dir/diff"

cleanup() {
  rm -rf "$review_tmp_dir"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  diff_label="git diff HEAD"
  if [ -n "$diff_path" ]; then
    git --no-pager --literal-pathspecs diff --no-ext-diff HEAD -- "$diff_path" >"$diff_file"
  else
    git --no-pager diff --no-ext-diff HEAD >"$diff_file"
  fi
else
  diff_label="staged diff plus working-copy delta (unborn HEAD)"
  if [ -n "$diff_path" ]; then
    git --no-pager --literal-pathspecs diff --cached --no-ext-diff -- "$diff_path" >"$diff_file"
    git --no-pager --literal-pathspecs diff --no-ext-diff -- "$diff_path" >>"$diff_file"
  else
    git --no-pager diff --cached --no-ext-diff >"$diff_file"
    git --no-pager diff --no-ext-diff >>"$diff_file"
  fi
fi

if [ -n "$diff_path" ]; then
  scope_status="$(git --literal-pathspecs status --porcelain -- "$diff_path")"
  review_status="$(git --literal-pathspecs status --short --branch -- "$diff_path")"
else
  scope_status="$(git status --porcelain)"
  review_status="$(git status --short --branch)"
fi

if [ "$review_mode" = "review" ] && \
  [ ! -s "$diff_file" ] && \
  [ -z "$scope_status" ]; then
  echo "Claude review unavailable: no tracked or untracked changes found in the selected scope. Set CLAUDE_REVIEW_MODE=audit for an intentional clean-tree audit." >&2
  exit 4
fi

diff_bytes="$(wc -c <"$diff_file" | tr -d '[:space:]')"
status_bytes="$(printf '%s\n' "$review_status" | wc -c | tr -d '[:space:]')"
evidence_bytes="$((diff_bytes + status_bytes))"
if [ "$evidence_bytes" -gt "$max_diff_bytes" ]; then
  echo "Claude review unavailable: review evidence is $evidence_bytes bytes, above CLAUDE_REVIEW_MAX_DIFF_BYTES=$max_diff_bytes. Scope it with CLAUDE_REVIEW_DIFF_PATH or raise the explicit limit." >&2
  exit 5
fi

echo "Running read-only Claude review with $model at $effort effort..." >&2
echo "Claude text output is buffered until completion; keep polling this process instead of launching a duplicate." >&2

claude_help="$("$claude_bin" --help 2>&1 || true)"

supports_flag() {
  printf '%s\n' "$claude_help" |
    grep -Eq -- "(^|[[:space:],])$1([[:space:],=]|$)"
}

set -- \
  --print \
  --model "$model" \
  --effort "$effort" \
  --permission-mode dontAsk \
  --output-format text

for optional_flag in \
  --tools \
  --strict-mcp-config \
  --disable-slash-commands \
  --exclude-dynamic-system-prompt-sections; do
  if ! supports_flag "$optional_flag"; then
    echo "Claude review notice: installed CLI lacks $optional_flag; continuing without that token-context optimization." >&2
  fi
done

if supports_flag --tools; then
  set -- "$@" --tools "Read,Grep,Glob"
else
  set -- "$@" \
    --allowedTools "Read" "Grep" "Glob" \
    --disallowedTools \
      "Bash" "Edit" "Write" "NotebookEdit" "MultiEdit" "Task" \
      "WebFetch" "WebSearch"
fi
if supports_flag --strict-mcp-config; then
  set -- "$@" --strict-mcp-config
fi
if supports_flag --disable-slash-commands; then
  set -- "$@" --disable-slash-commands
fi
if supports_flag --exclude-dynamic-system-prompt-sections; then
  set -- "$@" --exclude-dynamic-system-prompt-sections
fi

{
  printf '%s\n\n' "$role_preamble"
  printf '%s\n\n' "$prompt"
  printf '%s\n' \
    "The repository evidence below was captured by the read-only wrapper." \
    "Untracked paths appear in status but not in Git diffs; inspect them with Read or Glob." \
    "You may use Read, Grep, and Glob for more context. Do not edit files." \
    "" \
    "=== git status --short --branch ==="
  printf '%s\n' "$review_status"
  if [ -n "$diff_path" ]; then
    printf '%s\n' "" "=== $diff_label -- $diff_path ==="
  else
    printf '%s\n' "" "=== $diff_label ==="
  fi
  cat "$diff_file"
} | "$claude_bin" "$@"
