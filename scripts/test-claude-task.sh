#!/bin/sh

set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
test_tmp_base="${TMPDIR:-/tmp}"
test_dir="$(mktemp -d "${test_tmp_base%/}/test-claude-task.XXXXXX")"
cleanup() { rm -rf "$test_dir"; }
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p "$test_dir/bin" "$test_dir/work dir"
cp "$script_dir/claude-task.sh" "$test_dir/bin/opus-task"
cp "$script_dir/claude-task.sh" "$test_dir/bin/fable-task"
cp "$script_dir/claude-task.sh" "$test_dir/bin/unknown-task"
chmod +x "$test_dir/bin/opus-task" "$test_dir/bin/fable-task" "$test_dir/bin/unknown-task"
cat >"$test_dir/bin/claude" <<'EOF'
#!/bin/sh
case "$1" in
  auth)
    if [ "${FAKE_AUTH:-yes}" = yes ]; then
      printf '%s\n' '{"loggedIn":true}'
    else
      printf '%s\n' '{"loggedIn":false,"secret":"must never print"}'
    fi
    exit 0
    ;;
  --help)
    if [ "${FAKE_SHORT_HELP:-no}" = yes ]; then
      printf '%s\n' '--print --model --effort'
    else
      printf '%s\n' '--print --model --effort --restricted --tools --permission-mode --permission-prompts --strict-mcp-config --disable-slash-commands --no-session-persistence --output-format --exclude-dynamic-system-prompt-sections'
    fi
    exit 0
    ;;
esac
printf '%s\n' "$@" >"$CAPTURE_ARGS"
pwd >"$CAPTURE_CWD"
if [ -n "${CAPTURE_UMASK:-}" ]; then
  umask >"$CAPTURE_UMASK"
  : >"$CAPTURE_CREATED"
fi
if [ "${FAKE_SLEEP:-no}" = yes ]; then
  printf '%s\n' "$$" >"$CAPTURE_PID"
  exec sleep 30
fi
cat >"$CAPTURE_STDIN"
cat "$FAKE_RESULT"
exit "${FAKE_PROVIDER_STATUS:-0}"
EOF
chmod +x "$test_dir/bin/claude"

printf 'Edit only src/example.txt. Literal shell text: $(touch %s/injection) and `date`.\n' \
  "$test_dir" >"$test_dir/brief"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"permission_denials":[],"modelUsage":{"claude-opus-5-5":{}},"result":"Changed src/example.txt"}' >"$test_dir/opus.json"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"permission_denials":[],"modelUsage":{"claude-fable-5-1":{}},"result":"Fable result"}' >"$test_dir/fable.json"

export PATH="$test_dir/bin:/usr/bin:/bin"
export CAPTURE_ARGS="$test_dir/args"
export CAPTURE_CWD="$test_dir/cwd"
export CAPTURE_STDIN="$test_dir/stdin"
export FAKE_RESULT="$test_dir/opus.json"

"$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'Changed src/example.txt' "$test_dir/out"
grep -qxF "$test_dir/work dir" "$test_dir/cwd"
grep -qF "Literal shell text: \$(touch $test_dir/injection) and \`date\`." "$test_dir/stdin"
test ! -e "$test_dir/injection"
grep -qxF 'claude-opus-5-5' "$test_dir/args"
grep -qxF 'high' "$test_dir/args"
grep -qxF 'dontAsk' "$test_dir/args"
grep -qxF 'Read,Grep,Glob' "$test_dir/args"
grep -qxF 'none' "$test_dir/args"
grep -qF 'model=claude-opus-5-5 effort=high mode=read-only' "$test_dir/err"
printf '%s\n' 'Owner: Fable. Worker: Opus. Return decisions to Fable.' \
  >"$test_dir/fable-owner-brief"
"$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/fable-owner-brief" \
  >"$test_dir/out" 2>"$test_dir/err"
grep -qF 'The calling owner named in the brief keeps the plan' "$test_dir/stdin"
grep -qF 'Owner: Fable. Worker: Opus. Return decisions to Fable.' "$test_dir/stdin"
grep -qF 'decisions for the calling owner to integrate' "$test_dir/stdin"
if grep -qF 'Astra' "$test_dir/stdin"; then
  printf '%s\n' 'Claude task prompt replaced the Fable caller with Astra.' >&2
  exit 1
fi
if grep -qF '=== git diff' "$test_dir/stdin"; then
  printf '%s\n' 'Task helper attached repository evidence without a request.' >&2
  exit 1
fi
for required_flag in --restricted --strict-mcp-config --disable-slash-commands --no-session-persistence --output-format --exclude-dynamic-system-prompt-sections; do
  grep -qxF -- "$required_flag" "$test_dir/args"
done
for forbidden in --bare --fallback-model --dangerously-skip-permissions bypassPermissions Bash Agent; do
  if grep -qxF -- "$forbidden" "$test_dir/args"; then
    printf 'Unsafe argument used: %s\n' "$forbidden" >&2
    exit 1
  fi
done

FAKE_RESULT="$test_dir/fable.json" "$test_dir/bin/fable-task" --edit --effort xhigh \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'Fable result' "$test_dir/out"
grep -qxF 'claude-fable-5-1' "$test_dir/args"
grep -qxF 'xhigh' "$test_dir/args"
grep -qxF 'acceptEdits' "$test_dir/args"
grep -qxF 'Read,Grep,Glob,Edit,Write' "$test_dir/args"
grep -qF 'model=claude-fable-5-1 effort=xhigh mode=edit' "$test_dir/err"
"$test_dir/bin/opus-task" --read-only --effort low \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'low' "$test_dir/args"
grep -qxF 'dontAsk' "$test_dir/args"
(umask 022; CAPTURE_UMASK="$test_dir/worker-umask" \
  CAPTURE_CREATED="$test_dir/worker-created" \
  "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief" \
  >"$test_dir/out" 2>"$test_dir/err")
test "$(tr -d 0 <"$test_dir/worker-umask")" = 22
test "$(find "$test_dir/worker-created" -perm 644 -print)" = "$test_dir/worker-created"

expect_no_inference() {
  rm -f "$CAPTURE_ARGS"
  if "$@" >"$test_dir/out" 2>"$test_dir/err"; then
    printf 'Expected rejection before inference: %s\n' "$1" >&2
    exit 1
  fi
  test ! -e "$CAPTURE_ARGS"
  test ! -s "$test_dir/out"
}

expect_no_inference "$test_dir/bin/unknown-task" "$test_dir/work dir" "$test_dir/brief"
expect_no_inference "$test_dir/bin/opus-task" --model claude-fable-5-1 "$test_dir/work dir" "$test_dir/brief"
expect_no_inference "$test_dir/bin/opus-task" --effort extreme "$test_dir/work dir" "$test_dir/brief"
expect_no_inference "$test_dir/bin/opus-task" --effort
expect_no_inference "$test_dir/bin/opus-task" "$test_dir/missing" "$test_dir/brief"
expect_no_inference "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/missing"
(CLAUDE_TASK_MODEL=claude-fable-5-1 expect_no_inference "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief")
touch "$test_dir/empty"
expect_no_inference "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/empty"
printf ' \t\n \n' >"$test_dir/blank"
expect_no_inference "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/blank"
grep -qF 'nonblank text' "$test_dir/err"
dd if=/dev/zero of="$test_dir/large" bs=64001 count=1 2>/dev/null
expect_no_inference "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/large"
printf x >"$test_dir/limit"
dd if=/dev/zero bs=63999 count=1 2>/dev/null | tr '\000' x >>"$test_dir/limit"
"$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/limit" \
  >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'Changed src/example.txt' "$test_dir/out"
(FAKE_AUTH=no expect_no_inference "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief")
if grep -qF 'must never print' "$test_dir/err"; then
  printf '%s\n' 'Authentication preflight leaked provider detail.' >&2
  exit 1
fi
(FAKE_SHORT_HELP=yes expect_no_inference "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief")
grep -qF 'lacks --restricted' "$test_dir/err"

# Keep basic utilities available while deliberately hiding jq.
mkdir -p "$test_dir/no-jq"
for utility in basename wc tr grep rm; do
  ln -s "$(command -v "$utility")" "$test_dir/no-jq/$utility"
done
(PATH="$test_dir/no-jq" expect_no_inference "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief")
grep -qF 'jq is required' "$test_dir/err"

expect_bad_result() {
  rm -f "$CAPTURE_ARGS"
  if "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"; then
    printf '%s\n' 'Expected provider result rejection.' >&2
    exit 1
  fi
  test -e "$CAPTURE_ARGS"
  test ! -s "$test_dir/out"
  grep -qF 'Edits may remain in WORKDIR' "$test_dir/err"
  retained_file="$(sed -n 's/^Retained Claude result: //p' "$test_dir/err")"
  test -f "$retained_file"
  cmp -s "$FAKE_RESULT" "$retained_file"
  retained_dir="$(dirname "$retained_file")"
  test "$(find "$retained_dir" -perm 700 -print)" = "$retained_dir"
  test "$(find "$retained_file" -perm 600 -print)" = "$retained_file"
  test ! -e "$retained_dir/prompt"
  rm -rf "$retained_dir"
}

printf '%s\n' 'broken JSON' >"$test_dir/bad.json"
(FAKE_RESULT="$test_dir/bad.json" expect_bad_result)
grep -qF 'malformed or incomplete JSON' "$test_dir/err"
printf '%s\n' '{"type":"result","subtype":"error","is_error":true,"modelUsage":{"claude-opus-5-5":{}},"result":"error"}' >"$test_dir/bad.json"
(FAKE_RESULT="$test_dir/bad.json" expect_bad_result)
grep -qF '"subtype":"error"' "$test_dir/err"
grep -qF '"is_error":true' "$test_dir/err"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"permission_denials":[{"tool":"Write"}],"modelUsage":{"claude-opus-5-5":{}},"result":"partial"}' >"$test_dir/bad.json"
(FAKE_RESULT="$test_dir/bad.json" expect_bad_result)
grep -qF '"denial_count":1' "$test_dir/err"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"modelUsage":{"claude-fable-5-1":{}},"result":"wrong model"}' >"$test_dir/bad.json"
(FAKE_RESULT="$test_dir/bad.json" expect_bad_result)
grep -qF '"modelUsage_keys":["claude-fable-5-1"]' "$test_dir/err"
if grep -qF 'wrong model' "$test_dir/err"; then
  printf '%s\n' 'Unvalidated result text leaked into diagnostics.' >&2
  exit 1
fi
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"result":"no usage"}' >"$test_dir/bad.json"
(FAKE_RESULT="$test_dir/bad.json" expect_bad_result)
cat "$test_dir/opus.json" "$test_dir/opus.json" >"$test_dir/bad.json"
(FAKE_RESULT="$test_dir/bad.json" expect_bad_result)
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"permission_denials":[],"modelUsage":{"claude-opus-5-5":{},"claude-fable-5-1":{}},"result":"mixed models"}' >"$test_dir/bad.json"
(FAKE_RESULT="$test_dir/bad.json" expect_bad_result)

rm -f "$CAPTURE_ARGS"
provider_status=0
FAKE_PROVIDER_STATUS=23 "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief" \
  >"$test_dir/out" 2>"$test_dir/err" || provider_status=$?
test "$provider_status" -eq 23
test -e "$CAPTURE_ARGS"
test ! -s "$test_dir/out"
grep -qF 'provider exited 23' "$test_dir/err"
retained_file="$(sed -n 's/^Retained Claude result: //p' "$test_dir/err")"
test -f "$retained_file"
test ! -e "$(dirname "$retained_file")/prompt"
rm -rf "$(dirname "$retained_file")"

CAPTURE_PID="$test_dir/sleeping-pid" FAKE_SLEEP=yes \
  "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief" \
  >"$test_dir/out" 2>"$test_dir/err" &
wrapper_pid=$!
attempt=0
while [ ! -s "$test_dir/sleeping-pid" ] && [ "$attempt" -lt 50 ]; do
  sleep 0.1
  attempt=$((attempt + 1))
done
test -s "$test_dir/sleeping-pid"
worker_pid="$(cat "$test_dir/sleeping-pid")"
kill -0 "$worker_pid"
kill -TERM "$wrapper_pid"
signal_status=0
wait "$wrapper_pid" || signal_status=$?
test "$signal_status" -eq 143
if kill -0 "$worker_pid" 2>/dev/null; then
  printf 'Interrupted Claude process %s is still running.\n' "$worker_pid" >&2
  exit 1
fi
grep -qF 'interrupted by signal' "$test_dir/err"
retained_file="$(sed -n 's/^Retained Claude result: //p' "$test_dir/err")"
test -f "$retained_file"
test ! -e "$(dirname "$retained_file")/prompt"
rm -rf "$(dirname "$retained_file")"

printf '%s\n' 'Claude task helper tests passed.'
