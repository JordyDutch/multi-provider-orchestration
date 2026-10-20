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

# A developer's environment must not gate --advisor inside the suite.
unset CLAUDE_CODE_DISABLE_ADVISOR_TOOL DISABLE_GROWTHBOOK DO_NOT_TRACK \
  CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_MANTLE CLAUDE_CODE_USE_ANTHROPIC_AWS \
  CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY \
  DISABLE_TELEMETRY CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC

mkdir -p "$test_dir/bin" "$test_dir/work dir"
cp "$script_dir/claude-task.sh" "$test_dir/bin/opus-task"
cp "$script_dir/claude-task.sh" "$test_dir/bin/fable-task"
cp "$script_dir/claude-task.sh" "$test_dir/bin/sonnet-task"
cp "$script_dir/claude-task.sh" "$test_dir/bin/haiku-task"
cp "$script_dir/claude-task.sh" "$test_dir/bin/unknown-task"
chmod +x "$test_dir/bin/opus-task" "$test_dir/bin/fable-task" \
  "$test_dir/bin/sonnet-task" "$test_dir/bin/haiku-task" "$test_dir/bin/unknown-task"
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
      printf '%s' '--print --model --effort --restricted --tools --permission-mode --permission-prompts --strict-mcp-config --disable-slash-commands --no-session-persistence --output-format --exclude-dynamic-system-prompt-sections'
      if [ "${FAKE_NO_SETTINGS:-no}" != yes ]; then
        printf '%s' ' --settings'
      fi
      printf '\n'
    fi
    exit 0
    ;;
esac
# Only the --advisor probe omits --disable-slash-commands.
advisor_probe=yes
for fake_arg in "$@"; do
  [ "$fake_arg" != --disable-slash-commands ] || advisor_probe=no
done
if [ "$advisor_probe" = yes ]; then
  printf '%s\n' "$@" >"$CAPTURE_PROBE_ARGS"
  cat >"$CAPTURE_PROBE_STDIN"
  cat "$FAKE_PROBE_RESULT"
  exit "${FAKE_PROBE_STATUS:-0}"
fi
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
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"permission_denials":[],"modelUsage":{"claude-sonnet-5-5":{}},"result":"Sonnet result"}' >"$test_dir/sonnet.json"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"permission_denials":[],"modelUsage":{"claude-haiku-5-5":{}},"result":"Haiku result"}' >"$test_dir/haiku.json"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"permission_denials":[],"modelUsage":{"claude-haiku-5-5":{},"claude-fable-5-1":{}},"result":"Haiku advised result"}' >"$test_dir/advisor.json"
# Local /advisor output, recorded from Claude Code 2.1.304.
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"modelUsage":{},"result":"Advisor: Fable 5.1\nUsage: /advisor <fable|opus|sonnet|off>"}' >"$test_dir/probe-ok.json"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"modelUsage":{},"result":"/advisor isn'"'"'t available in this environment."}' >"$test_dir/probe-unavailable.json"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"modelUsage":{},"result":"Advisor: Opus 5.5\nUsage: /advisor <fable|opus|sonnet|off>"}' >"$test_dir/probe-opus.json"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"modelUsage":{},"result":"Advisor: Fable 5.1\nUsage: /advisor <sonnet|off>"}' >"$test_dir/probe-excluded.json"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"modelUsage":{"claude-haiku-5-5":{}},"result":"Advisor: Fable 5.1\nUsage: /advisor <fable|opus|sonnet|off>"}' >"$test_dir/probe-inference.json"
printf '%s\n' '{"type":"result","subtype":"error_during_execution","is_error":true,"modelUsage":{},"result":"Advisor: Fable 5.1\nUsage: /advisor <fable|opus|sonnet|off>"}' >"$test_dir/probe-error.json"

export PATH="$test_dir/bin:/usr/bin:/bin"
export CAPTURE_ARGS="$test_dir/args"
export CAPTURE_CWD="$test_dir/cwd"
export CAPTURE_STDIN="$test_dir/stdin"
export CAPTURE_PROBE_ARGS="$test_dir/probe-args"
export CAPTURE_PROBE_STDIN="$test_dir/probe-stdin"
export FAKE_RESULT="$test_dir/opus.json"
export FAKE_PROBE_RESULT="$test_dir/probe-ok.json"

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
grep -qF 'model=claude-opus-5-5 effort=high mode=read-only advisor=off' "$test_dir/err"
if grep -qxF -- '--settings' "$test_dir/args" || grep -qF 'advisorModel' "$test_dir/args"; then
  printf '%s\n' 'Advisor settings were passed without --advisor.' >&2
  exit 1
fi
if grep -qF 'advisor tool' "$test_dir/stdin"; then
  printf '%s\n' 'Advisor prompt line was added without --advisor.' >&2
  exit 1
fi
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
FAKE_RESULT="$test_dir/sonnet.json" "$test_dir/bin/sonnet-task" \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'Sonnet result' "$test_dir/out"
grep -qxF 'claude-sonnet-5-5' "$test_dir/args"
grep -qxF 'low' "$test_dir/args"
grep -qxF 'dontAsk' "$test_dir/args"
grep -qxF 'Read,Grep,Glob' "$test_dir/args"
grep -qxF -- '--restricted' "$test_dir/args"
grep -qxF -- '--no-session-persistence' "$test_dir/args"
grep -qF 'model=claude-sonnet-5-5 effort=low mode=read-only' "$test_dir/err"
FAKE_RESULT="$test_dir/sonnet.json" "$test_dir/bin/sonnet-task" --edit --effort medium \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'Sonnet result' "$test_dir/out"
grep -qxF 'medium' "$test_dir/args"
grep -qxF 'acceptEdits' "$test_dir/args"
grep -qxF 'Read,Grep,Glob,Edit,Write' "$test_dir/args"
grep -qF 'model=claude-sonnet-5-5 effort=medium mode=edit' "$test_dir/err"
rm -f "$CAPTURE_PROBE_ARGS"
FAKE_RESULT="$test_dir/haiku.json" "$test_dir/bin/haiku-task" \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
test ! -e "$CAPTURE_PROBE_ARGS"
grep -qxF 'Haiku result' "$test_dir/out"
grep -qxF 'claude-haiku-5-5' "$test_dir/args"
grep -qxF 'low' "$test_dir/args"
grep -qxF 'dontAsk' "$test_dir/args"
grep -qxF 'Read,Grep,Glob' "$test_dir/args"
grep -qF 'model=claude-haiku-5-5 effort=low mode=read-only advisor=off' "$test_dir/err"
grep -qF 'Claude task completed: model=claude-haiku-5-5 effort=low mode=read-only advisor=off' "$test_dir/err"
if grep -qxF -- '--settings' "$test_dir/args" || grep -qF 'advisorModel' "$test_dir/args"; then
  printf '%s\n' 'Haiku run passed advisor settings without --advisor.' >&2
  exit 1
fi
if grep -qF 'advisor tool' "$test_dir/stdin"; then
  printf '%s\n' 'Haiku prompt carried an advisor line without --advisor.' >&2
  exit 1
fi
FAKE_RESULT="$test_dir/haiku.json" "$test_dir/bin/haiku-task" --edit --effort medium \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'Haiku result' "$test_dir/out"
grep -qxF 'claude-haiku-5-5' "$test_dir/args"
grep -qxF 'medium' "$test_dir/args"
grep -qxF 'acceptEdits' "$test_dir/args"
grep -qxF 'Read,Grep,Glob,Edit,Write' "$test_dir/args"
grep -qF 'model=claude-haiku-5-5 effort=medium mode=edit advisor=off' "$test_dir/err"
FAKE_RESULT="$test_dir/advisor.json" "$test_dir/bin/haiku-task" --advisor \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'Haiku advised result' "$test_dir/out"
grep -qxF 'claude-haiku-5-5' "$test_dir/args"
grep -qxF -- '--settings' "$test_dir/args"
grep -qxF '{"advisorModel":"claude-fable-5-1"}' "$test_dir/args"
grep -qF 'An advisor tool backed by a stronger model is available.' "$test_dir/stdin"
grep -qF 'before reporting completion.' "$test_dir/stdin"
grep -qF 'Literal shell text:' "$test_dir/stdin"
grep -qF 'model=claude-haiku-5-5 effort=low mode=read-only advisor=claude-fable-5-1' "$test_dir/err"
grep -qF 'advisor=claude-fable-5-1 (called)' "$test_dir/err"
# The probe runs the same model and restricted settings, without the brief.
grep -qxF '/advisor' "$CAPTURE_PROBE_STDIN"
if grep -qF 'Literal shell text:' "$CAPTURE_PROBE_STDIN"; then
  printf '%s\n' 'The advisor probe received the brief.' >&2
  exit 1
fi
for probe_arg in --print claude-haiku-5-5 low --restricted --strict-mcp-config \
  --no-session-persistence --settings '{"advisorModel":"claude-fable-5-1"}' \
  dontAsk none; do
  grep -qxF -- "$probe_arg" "$CAPTURE_PROBE_ARGS"
done
awk 'previous == "--tools" { empty_tools = ($0 == "") } { previous = $0 }
  END { exit !empty_tools }' "$CAPTURE_PROBE_ARGS"
for forbidden in Read,Grep,Glob Edit Write Bash acceptEdits; do
  if grep -qF -- "$forbidden" "$CAPTURE_PROBE_ARGS"; then
    printf 'The advisor probe exposed %s.\n' "$forbidden" >&2
    exit 1
  fi
done
FAKE_RESULT="$test_dir/haiku.json" "$test_dir/bin/haiku-task" --advisor \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'Haiku result' "$test_dir/out"
grep -qxF '{"advisorModel":"claude-fable-5-1"}' "$test_dir/args"
grep -qF 'advisor=claude-fable-5-1 (not called)' "$test_dir/err"
FAKE_RESULT="$test_dir/fable.json" "$test_dir/bin/fable-task" --advisor \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"
grep -qxF 'Fable result' "$test_dir/out"
grep -qxF '{"advisorModel":"claude-fable-5-1"}' "$test_dir/args"
grep -qF 'advisor=claude-fable-5-1 (not distinguishable)' "$test_dir/err"
# Boolean off values, in any casing, do not disable the advisor.
for advisor_var in CLAUDE_CODE_DISABLE_ADVISOR_TOOL DISABLE_GROWTHBOOK DO_NOT_TRACK \
  CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_MANTLE CLAUDE_CODE_USE_ANTHROPIC_AWS \
  CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY; do
  for off_value in 0 FALSE No off; do
    (
      export "$advisor_var=$off_value"
      FAKE_RESULT="$test_dir/advisor.json" \
        "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief" \
        >"$test_dir/out" 2>"$test_dir/err"
    )
    grep -qxF 'Haiku advised result' "$test_dir/out"
    grep -qF 'advisor=claude-fable-5-1 (called)' "$test_dir/err"
  done
done
(DISABLE_TELEMETRY=1 FAKE_RESULT="$test_dir/haiku.json" \
  "$test_dir/bin/haiku-task" "$test_dir/work dir" "$test_dir/brief" \
  >"$test_dir/out" 2>"$test_dir/err")
grep -qxF 'Haiku result' "$test_dir/out"
(FAKE_NO_SETTINGS=yes FAKE_RESULT="$test_dir/haiku.json" \
  "$test_dir/bin/haiku-task" "$test_dir/work dir" "$test_dir/brief" \
  >"$test_dir/out" 2>"$test_dir/err")
grep -qxF 'Haiku result' "$test_dir/out"
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
(CLAUDE_TASK_MODEL=claude-sonnet-5 expect_no_inference "$test_dir/bin/sonnet-task" "$test_dir/work dir" "$test_dir/brief")
expect_no_inference "$test_dir/bin/sonnet-task" --model claude-sonnet-5 "$test_dir/work dir" "$test_dir/brief"
expect_no_inference "$test_dir/bin/sonnet-task" --effort ultracode "$test_dir/work dir" "$test_dir/brief"
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
(FAKE_NO_SETTINGS=yes expect_no_inference "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief")
grep -qF 'lacks --settings' "$test_dir/err"
expect_no_inference "$test_dir/bin/haiku-task" --advisor=x "$test_dir/work dir" "$test_dir/brief"
grep -qF 'unknown option: --advisor=x' "$test_dir/err"
for advisor_var in CLAUDE_CODE_DISABLE_ADVISOR_TOOL DISABLE_GROWTHBOOK DO_NOT_TRACK \
  CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_MANTLE CLAUDE_CODE_USE_ANTHROPIC_AWS \
  CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY \
  DISABLE_TELEMETRY CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC; do
  (
    export "$advisor_var=yes-hidden-value"
    expect_no_inference "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief"
  )
  grep -qF "$advisor_var" "$test_dir/err"
  grep -qF 'unavailable' "$test_dir/err"
  if grep -qF 'yes-hidden-value' "$test_dir/err"; then
    printf 'Advisor gating leaked the value of %s.\n' "$advisor_var" >&2
    exit 1
  fi
done
(DISABLE_TELEMETRY=0 expect_no_inference "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief")
grep -qF 'DISABLE_TELEMETRY' "$test_dir/err"
(CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=false expect_no_inference "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief")
grep -qF 'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC' "$test_dir/err"
# Managed settings act after the environment check; the restricted /advisor
# probe must confirm an allowed Fable 5.1 advisor before inference.
for probe_case in unavailable opus excluded inference error; do
  (FAKE_PROBE_RESULT="$test_dir/probe-$probe_case.json" \
    expect_no_inference "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief")
  grep -qF 'could not confirm an available Fable 5.1 advisor' "$test_dir/err"
done
(FAKE_PROBE_RESULT="$test_dir/probe-unavailable.json" \
  expect_no_inference "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief")
grep -qF "(reported: /advisor isn't available in this environment.)" "$test_dir/err"
(FAKE_PROBE_RESULT="$test_dir/probe-opus.json" \
  expect_no_inference "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief")
grep -qF '(reported: Advisor: Opus 5.5)' "$test_dir/err"
(FAKE_PROBE_RESULT="$test_dir/probe-inference.json" \
  expect_no_inference "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief")
grep -qF '(reported: no valid /advisor result)' "$test_dir/err"
(FAKE_PROBE_STATUS=1 expect_no_inference "$test_dir/bin/haiku-task" --advisor "$test_dir/work dir" "$test_dir/brief")
grep -qF '(reported: no valid /advisor result)' "$test_dir/err"
probe_status=0
FAKE_PROBE_RESULT="$test_dir/probe-unavailable.json" "$test_dir/bin/haiku-task" --advisor \
  "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err" || probe_status=$?
test "$probe_status" -eq 6

# Keep basic utilities available while deliberately hiding jq.
mkdir -p "$test_dir/no-jq"
for utility in basename wc tr grep rm; do
  ln -s "$(command -v "$utility")" "$test_dir/no-jq/$utility"
done
(PATH="$test_dir/no-jq" expect_no_inference "$test_dir/bin/opus-task" "$test_dir/work dir" "$test_dir/brief")
grep -qF 'jq is required' "$test_dir/err"

expect_bad_result() {
  result_helper=opus-task
  if [ "$#" -gt 0 ]; then
    result_helper="$1"
    shift
  fi
  rm -f "$CAPTURE_ARGS"
  if "$test_dir/bin/$result_helper" "$@" "$test_dir/work dir" "$test_dir/brief" >"$test_dir/out" 2>"$test_dir/err"; then
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

printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"permission_denials":[],"modelUsage":{"claude-sonnet-5":{}},"result":"older Sonnet"}' >"$test_dir/bad.json"
(FAKE_RESULT="$test_dir/bad.json" expect_bad_result sonnet-task)
grep -qF '"modelUsage_keys":["claude-sonnet-5"]' "$test_dir/err"
if grep -qF 'older Sonnet' "$test_dir/err"; then
  printf '%s\n' 'Unvalidated Sonnet result text leaked into diagnostics.' >&2
  exit 1
fi
(FAKE_RESULT="$test_dir/opus.json" expect_bad_result sonnet-task)
grep -qF '"modelUsage_keys":["claude-opus-5-5"]' "$test_dir/err"

# Advisor usage is accepted only when --advisor was requested, and only Fable.
(FAKE_RESULT="$test_dir/advisor.json" expect_bad_result haiku-task)
grep -qF '"modelUsage_keys":["claude-fable-5-1","claude-haiku-5-5"]' "$test_dir/err"
grep -qF 'advisor=off' "$test_dir/err"
(FAKE_RESULT="$test_dir/fable.json" expect_bad_result haiku-task --advisor)
grep -qF '"modelUsage_keys":["claude-fable-5-1"]' "$test_dir/err"
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"permission_denials":[],"modelUsage":{"claude-haiku-5-5":{},"claude-sonnet-5-5":{}},"result":"wrong advisor"}' >"$test_dir/bad.json"
(FAKE_RESULT="$test_dir/bad.json" expect_bad_result haiku-task --advisor)
grep -qF '"modelUsage_keys":["claude-haiku-5-5","claude-sonnet-5-5"]' "$test_dir/err"
if grep -qF 'wrong advisor' "$test_dir/err"; then
  printf '%s\n' 'Unvalidated advisor result text leaked into diagnostics.' >&2
  exit 1
fi
(FAKE_RESULT="$test_dir/opus.json" expect_bad_result haiku-task)
grep -qF '"modelUsage_keys":["claude-opus-5-5"]' "$test_dir/err"

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
