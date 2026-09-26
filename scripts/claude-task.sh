#!/bin/sh

set -eu

fail() {
  printf 'Claude task unavailable: %s\n' "$1" >&2
  exit "${2:-64}"
}

case "$(basename -- "$0")" in
  claude-task.sh|opus-task) model=claude-opus-5-5 ;;
  fable-task) model=claude-fable-5-1 ;;
  *) fail 'unknown entry point; use opus-task or fable-task.' ;;
esac

if [ "${CLAUDE_TASK_MODEL+x}" = x ]; then
  fail 'model overrides are disabled; the entry point pins the exact model.'
fi

mode=read-only
effort=high
while [ "$#" -gt 0 ]; do
  case "$1" in
    --read-only|--edit)
      mode="${1#--}"
      shift
      ;;
    --effort)
      [ "$#" -ge 2 ] || fail '--effort needs a value.'
      case "$2" in low|medium|high|xhigh|max) effort="$2" ;; *) fail 'effort must be low, medium, high, xhigh, or max.' ;; esac
      shift 2
      ;;
    --*) fail "unknown option: $1" ;;
    *) break ;;
  esac
done
[ "$#" -eq 2 ] || fail 'usage: opus-task|fable-task [--read-only|--edit] [--effort low|medium|high|xhigh|max] WORKDIR BRIEF_FILE'

workdir="$1"
brief_file="$2"
[ -d "$workdir" ] || fail 'WORKDIR must be an existing directory.'
[ -f "$brief_file" ] && [ -r "$brief_file" ] || fail 'BRIEF_FILE must be a readable regular file.'
brief_bytes="$(wc -c <"$brief_file" | tr -d '[:space:]')"
[ "$brief_bytes" -gt 0 ] && [ "$brief_bytes" -le 64000 ] || fail 'BRIEF_FILE must contain 1 to 64000 bytes.'
grep -q '[^[:space:]]' "$brief_file" || fail 'BRIEF_FILE must contain nonblank text.'

command -v jq >/dev/null 2>&1 || fail 'jq is required.' 127
claude_bin="$(command -v claude 2>/dev/null || true)"
if [ -z "$claude_bin" ] && [ -x "$HOME/.local/bin/claude" ]; then
  claude_bin="$HOME/.local/bin/claude"
fi
[ -n "$claude_bin" ] || fail 'the claude CLI is not on PATH.' 127

auth_status="$("$claude_bin" auth status 2>/dev/null || true)"
printf '%s\n' "$auth_status" | jq -e '.loggedIn == true' >/dev/null 2>&1 ||
  fail 'Claude Code is not authenticated. Run: claude auth login' 2

claude_help="$("$claude_bin" --help 2>/dev/null || true)"
supports_flag() {
  printf '%s\n' "$claude_help" | grep -Eq -- "(^|[[:space:],])$1([[:space:],=]|$)"
}
for required_flag in \
  --print --model --effort --restricted --tools --permission-mode \
  --permission-prompts --strict-mcp-config --disable-slash-commands \
  --no-session-persistence --output-format \
  --exclude-dynamic-system-prompt-sections; do
  supports_flag "$required_flag" || fail "installed Claude CLI lacks $required_flag." 6
done

caller_umask="$(umask)"
umask 077
task_tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/claude-task.XXXXXX")"
prompt_file="$task_tmp_dir/prompt"
result_file="$task_tmp_dir/result.json"
retain_result=no
provider_pid=''
cleanup() {
  if [ "$retain_result" = yes ]; then
    rm -f "$prompt_file" "$task_tmp_dir/result.txt"
  else
    rm -rf "$task_tmp_dir"
  fi
}
report_failure() {
  retain_result=yes
  printf 'Claude task failed: %s (model=%s effort=%s). Edits may remain in WORKDIR.\n' \
    "$1" "$model" "$effort" >&2
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

{
  printf '%s\n' \
    'You are a bounded Claude implementation specialist. The calling owner named in the brief keeps the plan, integration, and final authority.' \
    'Work only on the explicitly assigned paths and scope in the brief. Do not delegate, spawn agents, use Git, refresh global setup, or install anything.' \
    'Use only the available file tools. You cannot run tests or shell commands in this task; report checks that require the owner to run. Never claim those checks passed.' \
    'Return a compact report of changed files, checks actually performed, blockers, and decisions for the calling owner to integrate.' \
    '' \
    '=== Assigned brief ==='
  cat "$brief_file"
} >"$prompt_file"

set -- \
  --print \
  --model "$model" \
  --effort "$effort" \
  --restricted \
  --strict-mcp-config \
  --disable-slash-commands \
  --no-session-persistence \
  --output-format json \
  --exclude-dynamic-system-prompt-sections
if [ "$mode" = edit ]; then
  set -- "$@" --permission-mode acceptEdits --permission-prompts none \
    --tools 'Read,Grep,Glob,Edit,Write'
else
  set -- "$@" --permission-mode dontAsk --permission-prompts none \
    --tools 'Read,Grep,Glob'
fi

printf 'Running Claude task: model=%s effort=%s mode=%s\n' "$model" "$effort" "$mode" >&2
printf '%s\n' 'Claude output is buffered; poll this process rather than starting a duplicate.' >&2
: >"$result_file"
provider_status=0
(cd "$workdir" && umask "$caller_umask" && exec "$claude_bin" "$@" <"$prompt_file" >"$result_file") &
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
' "$result_file" >"$task_tmp_dir/result.txt" 2>/dev/null; then
  report_failure 'malformed, denied, or mismatched provider result' 7
fi
printf 'Claude task completed: model=%s effort=%s mode=%s\n' "$model" "$effort" "$mode" >&2
cat "$task_tmp_dir/result.txt"
