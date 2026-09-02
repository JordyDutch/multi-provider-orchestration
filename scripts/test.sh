#!/bin/sh

set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(dirname "$script_dir")"
test_home="$(mktemp -d)"
fake_bin="$test_home/fake-bin"

cleanup() {
  rm -r "$test_home"
}

trap cleanup EXIT HUP INT TERM

sh -n "$repo_dir/scripts/install-global.sh"
sh -n "$repo_dir/scripts/claude-review.sh"
sh -n "$repo_dir/scripts/sol-review.sh"
sh -n "$repo_dir/scripts/refresh-global-setup.sh"
git -C "$repo_dir" diff --check
grep -qF "**Parallelize independent work proactively.**" \
  "$repo_dir/AGENTS.md"
grep -qF "do not fan out again" "$repo_dir/AGENTS.md"
grep -qF "Collect every spawned process or agent result" \
  "$repo_dir/AGENTS.md"
grep -qF "Every Opus route means Claude Opus 5" "$repo_dir/AGENTS.md"
grep -qF "**Always pin Claude Fable to Fable 5.1.**" "$repo_dir/AGENTS.md"
grep -qF "**Choose reviews dynamically, with a confidence margin.**" \
  "$repo_dir/AGENTS.md"
grep -qF "**Standing external-review authorization.**" \
  "$repo_dir/AGENTS.md"
grep -qF "no stdout while its process is alive is not evidence" \
  "$repo_dir/AGENTS.md"
grep -qF "Every unqualified Opus reference" "$repo_dir/ORCHESTRATION.md"
grep -qF "Every unqualified Fable reference" "$repo_dir/ORCHESTRATION.md"
grep -qF "## Parallel work safety" "$repo_dir/ORCHESTRATION.md"
grep -qF "launch them together instead of waiting" \
  "$repo_dir/ORCHESTRATION.md"
grep -qF "Never let two agents edit the same file concurrently" \
  "$repo_dir/ORCHESTRATION.md"
grep -qF "Reap every process, collect every real exit status" \
  "$repo_dir/ORCHESTRATION.md"

HOME="$test_home" "$repo_dir/scripts/install-global.sh" >/dev/null
HOME="$test_home" "$repo_dir/scripts/install-global.sh" >/dev/null

cmp -s "$repo_dir/AGENTS.md" "$test_home/.codex/AGENTS.md"
cmp -s \
  "$repo_dir/ORCHESTRATION.md" "$test_home/.codex/ORCHESTRATION.md"
cmp -s \
  "$repo_dir/scripts/claude-review.sh" \
  "$test_home/.local/bin/claude-review"
cmp -s \
  "$repo_dir/scripts/claude-review.sh" \
  "$test_home/.local/bin/fable-review"
cmp -s \
  "$repo_dir/scripts/sol-review.sh" \
  "$test_home/.local/bin/sol-review"
cmp -s \
  "$repo_dir/scripts/refresh-global-setup.sh" \
  "$test_home/.local/bin/refresh-global-setup"
test "$(grep -c -xF '@~/.codex/AGENTS.md' \
  "$test_home/.claude/CLAUDE.md")" -eq 1

mkdir -p "$test_home/refresh-state"
printf '%s\n' '2099-01-01' >"$test_home/refresh-state/multi-provider-orchestration-refresh-date"
CODEX_SETUP_REPO="$test_home/missing-setup" \
  CODEX_SETUP_STATE_DIR="$test_home/refresh-state" \
  SETUP_REFRESH_DATE=2099-01-01 \
  "$repo_dir/scripts/refresh-global-setup.sh" >/dev/null

mkdir -p "$test_home/dirty-setup"
git -C "$test_home/dirty-setup" init -q
touch "$test_home/dirty-setup/uncommitted"
if CODEX_SETUP_REPO="$test_home/dirty-setup" \
  CODEX_SETUP_STATE_DIR="$test_home/refresh-state" \
  SETUP_REFRESH_DATE=2099-01-02 \
  "$repo_dir/scripts/refresh-global-setup.sh" \
  >"$test_home/dirty-refresh.stdout" 2>"$test_home/dirty-refresh.stderr"; then
  printf '%s\n' "Expected a dirty canonical setup checkout to block refresh." >&2
  exit 1
fi
grep -qF "has uncommitted changes" "$test_home/dirty-refresh.stderr"

mkdir -p "$fake_bin"

printf '%s\n' \
  '#!/bin/sh' \
  'if [ "$1" = "auth" ] && [ "$2" = "status" ]; then' \
  '  printf "%s\n" "{\"loggedIn\": true}"' \
  '  exit 0' \
  'fi' \
  'printf "%s\n" "$@" >"$CAPTURE_ARGS"' \
  'cat >"$CAPTURE_STDIN"' >"$fake_bin/claude"

printf '%s\n' \
  '#!/bin/sh' \
  'if [ "$1" = "login" ] && [ "$2" = "status" ]; then' \
  '  exit 0' \
  'fi' \
  'printf "%s\n" "$@" >"$CAPTURE_ARGS"' \
  'cat >"$CAPTURE_STDIN"' >"$fake_bin/codex"

chmod +x "$fake_bin/claude" "$fake_bin/codex"
cp "$repo_dir/scripts/claude-review.sh" "$fake_bin/claude-review"
cp "$repo_dir/scripts/claude-review.sh" "$fake_bin/fable-review"
chmod +x "$fake_bin/claude-review" "$fake_bin/fable-review"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/fable.args" \
  CAPTURE_STDIN="$test_home/fable.stdin" \
  "$fake_bin/fable-review" "Review only." >/dev/null

grep -qxF "claude-fable-5-1" "$test_home/fable.args"
grep -qxF "xhigh" "$test_home/fable.args"
grep -qF "Sol retains final integration" "$test_home/fable.stdin"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_MODEL=claude-fable-5-1 \
  CAPTURE_ARGS="$test_home/fable-env.args" \
  CAPTURE_STDIN="$test_home/fable-env.stdin" \
  "$fake_bin/claude-review" "Review only." >/dev/null

grep -qxF "claude-fable-5-1" "$test_home/fable-env.args"
grep -qxF "xhigh" "$test_home/fable-env.args"
grep -qF "Sol retains final integration" "$test_home/fable-env.stdin"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/opus.args" \
  CAPTURE_STDIN="$test_home/opus.stdin" \
  "$fake_bin/claude-review" "Review only." >/dev/null

grep -qxF "claude-opus-5" "$test_home/opus.args"
grep -qxF "high" "$test_home/opus.args"
grep -qF "smallest additional repository context needed" \
  "$test_home/opus.stdin"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_MODEL=claude-opus-4-8 \
  CAPTURE_ARGS="$test_home/old-opus.args" \
  CAPTURE_STDIN="$test_home/old-opus.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/old-opus.stdout" 2>"$test_home/old-opus.stderr"; then
  printf '%s\n' "Expected an older Opus model ID to be rejected." >&2
  exit 1
fi

grep -qF "model must be pinned to claude-opus-5 or claude-fable-5-1" \
  "$test_home/old-opus.stderr"
test ! -e "$test_home/old-opus.args"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_MODEL=claude-fable-5 \
  CAPTURE_ARGS="$test_home/old-fable.args" \
  CAPTURE_STDIN="$test_home/old-fable.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/old-fable.stdout" 2>"$test_home/old-fable.stderr"; then
  printf '%s\n' "Expected an older Fable model ID to be rejected." >&2
  exit 1
fi

grep -qF "model must be pinned to claude-opus-5 or claude-fable-5-1" \
  "$test_home/old-fable.stderr"
test ! -e "$test_home/old-fable.args"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_MODEL=fable \
  CAPTURE_ARGS="$test_home/fable-alias.args" \
  CAPTURE_STDIN="$test_home/fable-alias.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/fable-alias.stdout" \
  2>"$test_home/fable-alias.stderr"; then
  printf '%s\n' "Expected the bare Fable alias to be rejected." >&2
  exit 1
fi

grep -qF "model must be pinned to claude-opus-5 or claude-fable-5-1" \
  "$test_home/fable-alias.stderr"
test ! -e "$test_home/fable-alias.args"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/sol.args" \
  CAPTURE_STDIN="$test_home/sol.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." >/dev/null

grep -qxF "gpt-5.6-sol" "$test_home/sol.args"
grep -qxF 'model_reasoning_effort="xhigh"' "$test_home/sol.args"
grep -qxF "read-only" "$test_home/sol.args"
grep -qF "Fable retains final integration" "$test_home/sol.stdin"

printf '%s\n' "All orchestration tests passed."
