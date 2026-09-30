#!/bin/sh

set -eu

case "$(basename "$0")" in
  fable-review)
    default_model="claude-fable-5-1"
    ;;
  *)
    default_model="claude-opus-5-5"
    ;;
esac

model="${CLAUDE_REVIEW_MODEL:-$default_model}"
prompt="${*:-Review the current change adversarially for concrete bugs, regressions, and missing tests. Return findings ordered by severity with file and line evidence. Do not edit files.}"
review_mode="${CLAUDE_REVIEW_MODE:-review}"
diff_path="${CLAUDE_REVIEW_DIFF_PATH:-}"
max_diff_bytes="${CLAUDE_REVIEW_MAX_DIFF_BYTES:-200000}"

case "$model" in
  claude-opus-5-5)
    default_effort="high"
    ;;
  claude-fable-5-1)
    default_effort="xhigh"
    ;;
  *)
    echo "Claude review unavailable: model must be pinned to claude-opus-5-5 or claude-fable-5-1." >&2
    exit 64
    ;;
esac

effort="${CLAUDE_REVIEW_EFFORT:-$default_effort}"
case "$effort" in
  low|medium|high|xhigh|max) ;;
  *)
    echo "Claude review unavailable: CLAUDE_REVIEW_EFFORT must be low, medium, high, xhigh, or max." >&2
    exit 64
    ;;
esac

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

role_preamble="You are a bounded independent Claude reviewer. The calling orchestrator retains final integration and synthesis ownership. Use the supplied diff as primary evidence, inspect only the smallest additional repository context needed, return a final verdict promptly, and do not widen the task or claim final ownership. Do not delegate, spawn agents, refresh global setup, install anything, or edit files."

if ! command -v jq >/dev/null 2>&1; then
  echo "Claude review unavailable: jq is required to validate authentication and the provider result." >&2
  exit 127
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

auth_status="$("$claude_bin" auth status 2>/dev/null || true)"
if ! printf '%s\n' "$auth_status" | jq -e '.loggedIn == true' >/dev/null 2>&1; then
  echo "Claude review unavailable: Claude Code is not authenticated." >&2
  echo "Run: $claude_bin auth login" >&2
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Claude review unavailable: the current directory is not a Git worktree." >&2
  exit 3
fi

claude_help="$("$claude_bin" --help 2>/dev/null || true)"
supports_flag() {
  printf '%s\n' "$claude_help" |
    grep -Eq -- "(^|[[:space:],])$1([[:space:],=]|$)"
}
for required_flag in \
  --print --model --effort --restricted --tools --permission-mode \
  --permission-prompts --strict-mcp-config --disable-slash-commands \
  --no-session-persistence --output-format; do
  if ! supports_flag "$required_flag"; then
    echo "Claude review unavailable: installed CLI lacks $required_flag; update Claude Code." >&2
    exit 6
  fi
done

caller_umask="$(umask)"
umask 077
review_tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/claude-review.XXXXXX")"
diff_file="$review_tmp_dir/diff"
prompt_file="$review_tmp_dir/prompt"
result_file="$review_tmp_dir/result.json"
: >"$result_file"
retain_result=no
provider_pid=''

cleanup() {
  if [ "$retain_result" = yes ]; then
    rm -f "$diff_file" "$prompt_file" "$review_tmp_dir/result.txt"
  else
    rm -rf "$review_tmp_dir"
  fi
}
report_failure() {
  retain_result=yes
  printf 'Claude review failed: %s (model=%s effort=%s).\n' "$1" "$model" "$effort" >&2
  result_metadata="$(jq -cs '
    if length == 1 and (.[0] | type == "object") then .[0] else empty end
    | {
        subtype: (if (.subtype | type) == "string" then .subtype[:80] else null end),
        is_error: (if (.is_error | type) == "boolean" then .is_error else null end),
        denial_count: (if (.permission_denials | type) == "array" then (.permission_denials | length) else null end),
        modelUsage_keys: (if (.modelUsage | type) == "object" then (.modelUsage | keys[:8] | map(.[:80])) else [] end)
      }
  ' "$result_file" 2>/dev/null || true)"
  if [ -n "$result_metadata" ]; then
    printf 'Claude result metadata: %s\n' "$result_metadata" >&2
  else
    printf '%s\n' 'Claude result metadata: malformed or incomplete JSON.' >&2
  fi
  printf 'Retained Claude result: %s\n' "$result_file" >&2
  exit "$2"
}
on_signal() {
  trap - HUP INT TERM
  if [ -n "$provider_pid" ]; then
    kill -TERM "$provider_pid" 2>/dev/null || true
    wait "$provider_pid" 2>/dev/null || true
  fi
  report_failure 'interrupted by signal' "$1"
}

trap cleanup EXIT
trap 'on_signal 129' HUP
trap 'on_signal 130' INT
trap 'on_signal 143' TERM

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
  scope_status="$(git --literal-pathspecs status --porcelain --untracked-files=all -- "$diff_path")"
  review_status="$(git --literal-pathspecs status --short --branch --untracked-files=all -- "$diff_path")"
else
  scope_status="$(git status --porcelain --untracked-files=all)"
  review_status="$(git status --short --branch --untracked-files=all)"
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

set -- \
  --print \
  --model "$model" \
  --effort "$effort" \
  --restricted \
  --tools 'Read,Grep,Glob' \
  --permission-mode dontAsk \
  --permission-prompts none \
  --strict-mcp-config \
  --disable-slash-commands \
  --no-session-persistence \
  --output-format json
if supports_flag --exclude-dynamic-system-prompt-sections; then
  set -- "$@" --exclude-dynamic-system-prompt-sections
else
  echo "Claude review notice: installed CLI lacks --exclude-dynamic-system-prompt-sections; continuing without that token-context optimization." >&2
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
} >"$prompt_file"

provider_status=0
(umask "$caller_umask" && exec "$claude_bin" "$@" <"$prompt_file" >"$result_file") &
provider_pid=$!
wait "$provider_pid" || provider_status=$?
provider_pid=''
if [ "$provider_status" -ne 0 ]; then
  report_failure "provider exited $provider_status" "$provider_status"
fi

if ! jq -ers --arg model "$model" '
  if length == 1 and (.[0] | type == "object") then .[0] else empty end
  | if .type == "result" and .subtype == "success" and .is_error == false
      and (.permission_denials == null or .permission_denials == [])
      and (.modelUsage | type == "object" and (keys == [$model]))
      and (.result | type == "string" and length > 0)
    then .result else empty end
' "$result_file" >"$review_tmp_dir/result.txt" 2>/dev/null; then
  report_failure 'malformed, denied, or mismatched provider result' 7
fi
printf 'Claude review completed: model=%s effort=%s\n' "$model" "$effort" >&2
cat "$review_tmp_dir/result.txt"
