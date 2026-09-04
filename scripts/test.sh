#!/bin/sh

set -eu

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(dirname "$script_dir")"
test_home="$(mktemp -d)"
fake_bin="$test_home/fake-bin"

cleanup() {
  rm -r "$test_home"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

sh -n "$repo_dir/scripts/install-global.sh"
sh -n "$repo_dir/scripts/claude-review.sh"
sh -n "$repo_dir/scripts/sol-review.sh"
sh -n "$repo_dir/scripts/refresh-global-setup.sh"
git -C "$repo_dir" diff --check
test "$(wc -l <"$repo_dir/AGENTS.md")" -le 30
test "$(wc -c <"$repo_dir/AGENTS.md")" -le 1500
test ! "$repo_dir/AGENTS.md" -ef "$repo_dir/shared/AGENTS.md"
if cmp -s "$repo_dir/AGENTS.md" "$repo_dir/shared/AGENTS.md"; then
  printf '%s\n' "Root bootstrap must differ from the shared baseline." >&2
  exit 1
fi
if grep -qF "MPO_SHARED_BASELINE_V1" "$repo_dir/AGENTS.md"; then
  printf '%s\n' "Root bootstrap must not contain the joined baseline marker." >&2
  exit 1
fi
grep -qF 'earlier higher-level instruction explicitly states' \
  "$repo_dir/AGENTS.md"
grep -qF 'read `shared/AGENTS.md`' "$repo_dir/AGENTS.md"
grep -qF "MPO_SHARED_BASELINE_V1" "$repo_dir/shared/AGENTS.md"
grep -qF 'exact `claude-opus-5`' "$repo_dir/shared/AGENTS.md"
grep -qF '`claude-fable-5-1`' "$repo_dir/shared/AGENTS.md"
grep -qF "In Codex-led work and hand-offs" \
  "$repo_dir/shared/AGENTS.md"
grep -qF 'Luna (`gpt-5.6-luna`) at `low`' \
  "$repo_dir/shared/AGENTS.md"
grep -qF "repeatable extraction, classification, transformation" \
  "$repo_dir/shared/AGENTS.md"
grep -qF 'Terra (`gpt-5.6-terra`) at' \
  "$repo_dir/shared/AGENTS.md"
grep -qF '`medium` for bounded analysis, implementation, or tests' \
  "$repo_dir/shared/AGENTS.md"
grep -qF 'and `high` for bounded' \
  "$repo_dir/shared/AGENTS.md"
grep -qF 'live-verified Sonnet 5 at `low`/`medium`' \
  "$repo_dir/shared/AGENTS.md"
grep -qF "Every owner verifies" "$repo_dir/shared/AGENTS.md"
grep -qF 'Sol (`gpt-5.6-sol`) owns complex Codex work' \
  "$repo_dir/shared/AGENTS.md"
grep -qF "Independent reviews choose their effort" \
  "$repo_dir/shared/AGENTS.md"
grep -qF "does not require a second provider" \
  "$repo_dir/shared/AGENTS.md"
grep -qF "The helpers preflight authentication themselves" \
  "$repo_dir/shared/AGENTS.md"
grep -qF "Silence while the process is alive is not a" \
  "$repo_dir/shared/AGENTS.md"
grep -qF "prevent nested delegation" "$repo_dir/shared/AGENTS.md"
grep -qF "refresh-global-setup" "$repo_dir/shared/AGENTS.md"
test "$(wc -c <"$repo_dir/shared/AGENTS.md")" -le 5000
test "$(wc -c <"$repo_dir/shared/ORCHESTRATION.md")" -le 2500

for source_playbook in "$repo_dir"/shared/playbooks/*.md; do
  test -f "$source_playbook"
  playbook="$(basename "$source_playbook")"
  test "$(wc -c <"$source_playbook")" -le 6000
  grep -qF "playbooks/$playbook" "$repo_dir/shared/ORCHESTRATION.md"
done

router_links="$(sed -nE 's/.*\((playbooks\/[^)]*\.md)\).*/\1/p' \
  "$repo_dir/shared/ORCHESTRATION.md")"
for router_link in $router_links; do
  test -f "$repo_dir/shared/$router_link"
done

grep -qF "read every playbook by default" \
  "$repo_dir/shared/ORCHESTRATION.md"
grep -qF "focused verification; no automatic review" \
  "$repo_dir/shared/ORCHESTRATION.md"
grep -qF '`playbooks/routing.md` is the canonical model and effort ladder' \
  "$repo_dir/shared/ORCHESTRATION.md"
grep -qF '| Codex owner | GPT-5.6 Sol (`gpt-5.6-sol`) | `high` |' \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF '| Codex everyday | GPT-5.6 Terra (`gpt-5.6-terra`) | `medium` |' \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF '| Codex efficient | GPT-5.6 Luna (`gpt-5.6-luna`) | `low` |' \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF '| Claude efficient | Sonnet 5 (`claude-sonnet-5`) | `low` |' \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF "in Claude-led work, keep the active owner or use verified Sonnet" \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF "work to Sol high or Claude-led work to Fable high" \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF "current entry owner integrates" \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF "Review provider follows the implementation author" \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF 'prefer Sol over compensating with `xhigh`' \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF "Reclassify and promote the model when the task changes class" \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF 'Review routes in `reviews.md` choose effort separately' \
  "$repo_dir/shared/playbooks/routing.md"
grep -qF "One owner scopes the behavior and verification" \
  "$repo_dir/shared/playbooks/execution.md"
grep -qF "Never let two workers edit the same file concurrently" \
  "$repo_dir/shared/playbooks/execution.md"
grep -qF "risk-based routes" "$repo_dir/shared/playbooks/reviews.md"
grep -qF "shared/AGENTS.md" "$repo_dir/shared/playbooks/setup.md"
grep -qF 'Luna (`gpt-5.6-luna`) at `low`' "$repo_dir/README.md"
grep -qF 'Terra (`gpt-5.6-terra`) at `medium`' "$repo_dir/README.md"
grep -qF 'Sol (`gpt-5.6-sol`) at `high`' "$repo_dir/README.md"
grep -qF "ambiguity promotes the route to Sol" "$repo_dir/README.md"
grep -qF "shared/ORCHESTRATION.md" "$repo_dir/ORCHESTRATION.md"

mkdir -p "$test_home/.claude"
printf '%s\n' "Keep this Claude-only instruction." >"$test_home/.claude/CLAUDE.md"
HOME="$test_home" "$repo_dir/scripts/install-global.sh" >/dev/null
HOME="$test_home" "$repo_dir/scripts/install-global.sh" >/dev/null

cmp -s "$repo_dir/shared/AGENTS.md" "$test_home/.codex/AGENTS.md"
cmp -s \
  "$repo_dir/shared/ORCHESTRATION.md" \
  "$test_home/.codex/ORCHESTRATION.md"
for source_playbook in "$repo_dir"/shared/playbooks/*.md; do
  playbook="$(basename "$source_playbook")"
  cmp -s \
    "$source_playbook" \
    "$test_home/.codex/playbooks/$playbook"
done
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
  "$repo_dir/scripts/sol-review.sh" \
  "$test_home/.local/bin/astra-review"
test -x "$test_home/.local/bin/astra-review"
cmp -s \
  "$repo_dir/scripts/refresh-global-setup.sh" \
  "$test_home/.local/bin/refresh-global-setup"
test "$(grep -c -xF '@~/.codex/AGENTS.md' \
  "$test_home/.claude/CLAUDE.md")" -eq 1
grep -qF "Keep this Claude-only instruction." \
  "$test_home/.claude/CLAUDE.md"

mkdir -p "$test_home/refresh-state"
printf '%s\n' '2099-01-01' >"$test_home/refresh-state/multi-provider-orchestration-refresh-date"
CODEX_SETUP_REPO="$test_home/missing-setup" \
  CODEX_SETUP_STATE_DIR="$test_home/refresh-state" \
  SETUP_REFRESH_DATE=2099-01-01 \
  "$repo_dir/scripts/refresh-global-setup.sh" >/dev/null

mkdir -p "$test_home/dirty-setup"
git -c init.templateDir= -C "$test_home/dirty-setup" init -q
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
  'if [ "$1" = "--help" ]; then' \
  '  if [ "${FAKE_CLAUDE_HELP:-full}" = "full" ]; then' \
  '    printf "%s\n" "--tools --strict-mcp-config --disable-slash-commands --exclude-dynamic-system-prompt-sections"' \
  '  else' \
  '    printf "%s\n" "Usage: claude"' \
  '  fi' \
  '  exit 0' \
  'fi' \
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
  'cat >"$CAPTURE_STDIN"' \
  'if [ -n "${CAPTURE_CALLS:-}" ]; then printf "%s\n" call >>"$CAPTURE_CALLS"; fi' \
  'exit "${FAKE_CODEX_STATUS:-0}"' >"$fake_bin/codex"

chmod +x "$fake_bin/claude" "$fake_bin/codex"
cp "$repo_dir/scripts/claude-review.sh" "$fake_bin/claude-review"
cp "$repo_dir/scripts/claude-review.sh" "$fake_bin/fable-review"
chmod +x "$fake_bin/claude-review" "$fake_bin/fable-review"

review_repo="$test_home/review-repo"
mkdir -p "$review_repo"
git -c init.templateDir= -C "$review_repo" init -q
printf '%s\n' "before" >"$review_repo/tracked.txt"
git -C "$review_repo" add tracked.txt
git -C "$review_repo" \
  -c commit.gpgsign=false \
  -c user.name="Orchestration Tests" \
  -c user.email="tests@example.invalid" \
  commit -qm "Add review fixture"
printf '%s\n' "after" >"$review_repo/tracked.txt"
cd "$review_repo"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/fable.args" \
  CAPTURE_STDIN="$test_home/fable.stdin" \
  "$fake_bin/fable-review" "Review only." >/dev/null

grep -qxF "claude-fable-5-1" "$test_home/fable.args"
grep -qxF "xhigh" "$test_home/fable.args"
grep -qxF -- "--tools" "$test_home/fable.args"
grep -qxF "Read,Grep,Glob" "$test_home/fable.args"
grep -qxF -- "--strict-mcp-config" "$test_home/fable.args"
grep -qxF -- "--disable-slash-commands" "$test_home/fable.args"
grep -qxF -- "--exclude-dynamic-system-prompt-sections" "$test_home/fable.args"
grep -qF "The calling orchestrator retains final integration" "$test_home/fable.stdin"
grep -qF "=== git diff HEAD ===" "$test_home/fable.stdin"
grep -qF "diff --git a/tracked.txt b/tracked.txt" "$test_home/fable.stdin"
if grep -qF "=== unstaged diff ===" "$test_home/fable.stdin" || \
  grep -qF "=== staged diff ===" "$test_home/fable.stdin"; then
  printf '%s\n' "Expected one combined HEAD diff, not separate staged and unstaged diffs." >&2
  exit 1
fi

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_MAX_DIFF_BYTES=1 \
  CAPTURE_ARGS="$test_home/oversized.args" \
  CAPTURE_STDIN="$test_home/oversized.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/oversized.stdout" 2>"$test_home/oversized.stderr"; then
  printf '%s\n' "Expected an oversized Claude review diff to be rejected." >&2
  exit 1
fi

grep -qF "above CLAUDE_REVIEW_MAX_DIFF_BYTES=1" \
  "$test_home/oversized.stderr"
test ! -e "$test_home/oversized.args"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_MODEL=claude-fable-5-1 \
  CAPTURE_ARGS="$test_home/fable-env.args" \
  CAPTURE_STDIN="$test_home/fable-env.stdin" \
  "$fake_bin/claude-review" "Review only." >/dev/null

grep -qxF "claude-fable-5-1" "$test_home/fable-env.args"
grep -qxF "xhigh" "$test_home/fable-env.args"
grep -qF "The calling orchestrator retains final integration" "$test_home/fable-env.stdin"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/opus.args" \
  CAPTURE_STDIN="$test_home/opus.stdin" \
  "$fake_bin/claude-review" "Review only." >/dev/null

grep -qxF "claude-opus-5" "$test_home/opus.args"
grep -qxF "high" "$test_home/opus.args"
grep -qF "smallest additional repository context needed" \
  "$test_home/opus.stdin"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  FAKE_CLAUDE_HELP=none \
  CAPTURE_ARGS="$test_home/degraded-help.args" \
  CAPTURE_STDIN="$test_home/degraded-help.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/degraded-help.stdout" \
  2>"$test_home/degraded-help.stderr"

for optional_flag in \
  --tools \
  --strict-mcp-config \
  --disable-slash-commands \
  --exclude-dynamic-system-prompt-sections; do
  if grep -qxF -- "$optional_flag" "$test_home/degraded-help.args"; then
    printf 'Unsupported flag was passed to Claude: %s\n' \
      "$optional_flag" >&2
    exit 1
  fi
  grep -qF "installed CLI lacks $optional_flag" \
    "$test_home/degraded-help.stderr"
done
grep -qxF -- "--allowedTools" "$test_home/degraded-help.args"
grep -qxF -- "--disallowedTools" "$test_home/degraded-help.args"
grep -qxF "MultiEdit" "$test_home/degraded-help.args"
grep -qxF "Task" "$test_home/degraded-help.args"
grep -qxF "WebFetch" "$test_home/degraded-help.args"

printf '%s\n' "unrelated" >"$review_repo/unrelated.txt"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_DIFF_PATH=tracked.txt \
  CAPTURE_ARGS="$test_home/scoped.args" \
  CAPTURE_STDIN="$test_home/scoped.stdin" \
  "$fake_bin/claude-review" "Review only." >/dev/null

grep -qF "=== git diff HEAD -- tracked.txt ===" "$test_home/scoped.stdin"
grep -qF "diff --git a/tracked.txt b/tracked.txt" "$test_home/scoped.stdin"
if grep -qF "unrelated.txt" "$test_home/scoped.stdin"; then
  printf '%s\n' "Scoped Claude review leaked an unrelated path." >&2
  exit 1
fi
rm -f "$review_repo/unrelated.txt"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_DIFF_PATH=../tracked.txt \
  CAPTURE_ARGS="$test_home/parent-path.args" \
  CAPTURE_STDIN="$test_home/parent-path.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/parent-path.stdout" 2>"$test_home/parent-path.stderr"; then
  printf '%s\n' "Expected a parent-traversal review path to be rejected." >&2
  exit 1
fi

grep -qF "must be a relative path without parent traversal" \
  "$test_home/parent-path.stderr"
test ! -e "$test_home/parent-path.args"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_DIFF_PATH=/tmp/tracked.txt \
  CAPTURE_ARGS="$test_home/absolute-path.args" \
  CAPTURE_STDIN="$test_home/absolute-path.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/absolute-path.stdout" 2>"$test_home/absolute-path.stderr"; then
  printf '%s\n' "Expected an absolute review path to be rejected." >&2
  exit 1
fi

grep -qF "must be a relative path without parent traversal" \
  "$test_home/absolute-path.stderr"
test ! -e "$test_home/absolute-path.args"

git checkout -- tracked.txt

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/empty-diff.args" \
  CAPTURE_STDIN="$test_home/empty-diff.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/empty-diff.stdout" 2>"$test_home/empty-diff.stderr"; then
  printf '%s\n' "Expected an empty default review diff to be rejected." >&2
  exit 1
fi

grep -qF "no tracked or untracked changes found" \
  "$test_home/empty-diff.stderr"
test ! -e "$test_home/empty-diff.args"

printf '%s\n' "new" >"$review_repo/untracked.txt"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/untracked.args" \
  CAPTURE_STDIN="$test_home/untracked.stdin" \
  "$fake_bin/claude-review" "Review only." >/dev/null

grep -qF "?? untracked.txt" "$test_home/untracked.stdin"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_MAX_DIFF_BYTES=1 \
  CAPTURE_ARGS="$test_home/status-cap-claude.args" \
  CAPTURE_STDIN="$test_home/status-cap-claude.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/status-cap-claude.stdout" \
  2>"$test_home/status-cap-claude.stderr"; then
  printf '%s\n' "Expected Claude status evidence to count toward the cap." >&2
  exit 1
fi
grep -qF "above CLAUDE_REVIEW_MAX_DIFF_BYTES=1" \
  "$test_home/status-cap-claude.stderr"
test ! -e "$test_home/status-cap-claude.args"
rm -f "$review_repo/untracked.txt"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_MODE=audit \
  CAPTURE_ARGS="$test_home/audit.args" \
  CAPTURE_STDIN="$test_home/audit.stdin" \
  "$fake_bin/claude-review" "Review only." >/dev/null

grep -qF "=== git diff HEAD ===" "$test_home/audit.stdin"
if grep -qF "diff --git" "$test_home/audit.stdin"; then
  printf '%s\n' "Expected a clean-tree audit to send no Git diff." >&2
  exit 1
fi

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

printf '%s\n' "after-sol" >"$review_repo/tracked.txt"

PATH="$fake_bin:/usr/bin:/bin" \
  ASTRA_REVIEW_MODEL=unavailable ASTRA_REVIEW_EFFORT=max ASTRA_REVIEW_MODE=invalid \
  ASTRA_REVIEW_DIFF_PATH=../private ASTRA_REVIEW_MAX_DIFF_BYTES=1 \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/sol.args" \
  CAPTURE_STDIN="$test_home/sol.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." >/dev/null

grep -qxF "gpt-5.6-sol" "$test_home/sol.args"
grep -qxF 'model_reasoning_effort="xhigh"' "$test_home/sol.args"
grep -qxF "read-only" "$test_home/sol.args"
grep -qF "The calling orchestrator retains final integration" "$test_home/sol.stdin"
grep -qF "=== git diff HEAD ===" "$test_home/sol.stdin"
grep -qF "diff --git a/tracked.txt b/tracked.txt" "$test_home/sol.stdin"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  SOL_REVIEW_MAX_DIFF_BYTES=1 \
  CAPTURE_ARGS="$test_home/sol-oversized.args" \
  CAPTURE_STDIN="$test_home/sol-oversized.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." \
  >"$test_home/sol-oversized.stdout" \
  2>"$test_home/sol-oversized.stderr"; then
  printf '%s\n' "Expected an oversized Sol review diff to be rejected." >&2
  exit 1
fi

grep -qF "above SOL_REVIEW_MAX_DIFF_BYTES=1" \
  "$test_home/sol-oversized.stderr"
test ! -e "$test_home/sol-oversized.args"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  SOL_REVIEW_DIFF_PATH=tracked.txt \
  CAPTURE_ARGS="$test_home/sol-scoped.args" \
  CAPTURE_STDIN="$test_home/sol-scoped.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." >/dev/null

grep -qF "=== git diff HEAD -- tracked.txt ===" \
  "$test_home/sol-scoped.stdin"

printf '%s\n' "unrelated-sol" >"$review_repo/unrelated-sol.txt"
PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  SOL_REVIEW_DIFF_PATH=tracked.txt \
  CAPTURE_ARGS="$test_home/sol-private-scope.args" \
  CAPTURE_STDIN="$test_home/sol-private-scope.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." >/dev/null
if grep -qF "unrelated-sol.txt" "$test_home/sol-private-scope.stdin"; then
  printf '%s\n' "Scoped Sol review leaked an unrelated path." >&2
  exit 1
fi
rm -f "$review_repo/unrelated-sol.txt"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  SOL_REVIEW_DIFF_PATH=../tracked.txt \
  CAPTURE_ARGS="$test_home/sol-parent.args" \
  CAPTURE_STDIN="$test_home/sol-parent.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." \
  >"$test_home/sol-parent.stdout" 2>"$test_home/sol-parent.stderr"; then
  printf '%s\n' "Expected a parent-traversal Sol review path to be rejected." >&2
  exit 1
fi

grep -qF "must be a relative path without parent traversal" \
  "$test_home/sol-parent.stderr"
test ! -e "$test_home/sol-parent.args"

git checkout -- tracked.txt

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/sol-empty.args" \
  CAPTURE_STDIN="$test_home/sol-empty.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." \
  >"$test_home/sol-empty.stdout" 2>"$test_home/sol-empty.stderr"; then
  printf '%s\n' "Expected an empty default Sol review diff to be rejected." >&2
  exit 1
fi

grep -qF "no tracked or untracked changes found" \
  "$test_home/sol-empty.stderr"
test ! -e "$test_home/sol-empty.args"

printf '%s\n' "status-only" >"$review_repo/sol-status-only.txt"
if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  SOL_REVIEW_MAX_DIFF_BYTES=1 \
  CAPTURE_ARGS="$test_home/status-cap-sol.args" \
  CAPTURE_STDIN="$test_home/status-cap-sol.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." \
  >"$test_home/status-cap-sol.stdout" \
  2>"$test_home/status-cap-sol.stderr"; then
  printf '%s\n' "Expected Sol status evidence to count toward the cap." >&2
  exit 1
fi
grep -qF "above SOL_REVIEW_MAX_DIFF_BYTES=1" \
  "$test_home/status-cap-sol.stderr"
test ! -e "$test_home/status-cap-sol.args"
rm -f "$review_repo/sol-status-only.txt"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  SOL_REVIEW_MODE=audit \
  CAPTURE_ARGS="$test_home/sol-audit.args" \
  CAPTURE_STDIN="$test_home/sol-audit.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." >/dev/null

grep -qF "=== git diff HEAD ===" "$test_home/sol-audit.stdin"

unborn_repo="$test_home/unborn-repo"
mkdir -p "$unborn_repo"
git -c init.templateDir= -C "$unborn_repo" init -q
printf '%s\n' "first" >"$unborn_repo/first.txt"
git -C "$unborn_repo" add first.txt
printf '%s\n' "working-copy" >"$unborn_repo/first.txt"
cd "$unborn_repo"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/unborn-claude.args" \
  CAPTURE_STDIN="$test_home/unborn-claude.stdin" \
  "$fake_bin/claude-review" "Review only." >/dev/null

grep -qF "=== staged diff plus working-copy delta (unborn HEAD) ===" \
  "$test_home/unborn-claude.stdin"
grep -qF "diff --git a/first.txt b/first.txt" \
  "$test_home/unborn-claude.stdin"
grep -qF "+working-copy" "$test_home/unborn-claude.stdin"
grep -qxF "+first" "$test_home/unborn-claude.stdin"

PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CAPTURE_ARGS="$test_home/unborn-sol.args" \
  CAPTURE_STDIN="$test_home/unborn-sol.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." >/dev/null

grep -qF "=== staged diff plus working-copy delta (unborn HEAD) ===" \
  "$test_home/unborn-sol.stdin"
grep -qF "diff --git a/first.txt b/first.txt" \
  "$test_home/unborn-sol.stdin"
grep -qF "+working-copy" "$test_home/unborn-sol.stdin"
grep -qxF "+first" "$test_home/unborn-sol.stdin"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  CLAUDE_REVIEW_DIFF_PATH=missing.txt \
  CAPTURE_ARGS="$test_home/unborn-missing-claude.args" \
  CAPTURE_STDIN="$test_home/unborn-missing-claude.stdin" \
  "$fake_bin/claude-review" "Review only." \
  >"$test_home/unborn-missing-claude.stdout" \
  2>"$test_home/unborn-missing-claude.stderr"; then
  printf '%s\n' "Expected missing unborn Claude scope to fail cleanly." >&2
  exit 1
fi
grep -qF "no tracked or untracked changes found" \
  "$test_home/unborn-missing-claude.stderr"
test ! -e "$test_home/unborn-missing-claude.args"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  SOL_REVIEW_DIFF_PATH=missing.txt \
  CAPTURE_ARGS="$test_home/unborn-missing-sol.args" \
  CAPTURE_STDIN="$test_home/unborn-missing-sol.stdin" \
  "$repo_dir/scripts/sol-review.sh" "Review only." \
  >"$test_home/unborn-missing-sol.stdout" \
  2>"$test_home/unborn-missing-sol.stderr"; then
  printf '%s\n' "Expected missing unborn Sol scope to fail cleanly." >&2
  exit 1
fi
grep -qF "no tracked or untracked changes found" \
  "$test_home/unborn-missing-sol.stderr"
test ! -e "$test_home/unborn-missing-sol.args"

# Exercise the installed Astra entry point, including isolation from Sol settings.
cd "$review_repo"
printf '%s\n' "astra-change" >tracked.txt
astra_helper="$test_home/.local/bin/astra-review"
PATH="$fake_bin:/usr/bin:/bin" \
  SOL_REVIEW_MODEL=unavailable SOL_REVIEW_EFFORT=max SOL_REVIEW_MODE=invalid \
  SOL_REVIEW_DIFF_PATH=../private SOL_REVIEW_MAX_DIFF_BYTES=1 \
  CAPTURE_ARGS="$test_home/astra.args" \
  CAPTURE_STDIN="$test_home/astra.stdin" \
  "$astra_helper" "Review only." >/dev/null
grep -qxF "gpt-6-astra" "$test_home/astra.args"
grep -qxF 'model_reasoning_effort="high"' "$test_home/astra.args"
grep -qxF "read-only" "$test_home/astra.args"
grep -qxF -- "--ephemeral" "$test_home/astra.args"
grep -qF "The calling orchestrator retains final integration" "$test_home/astra.stdin"
grep -qF "+astra-change" "$test_home/astra.stdin"

printf '%s\n' "unrelated" >unrelated-astra.txt
PATH="$fake_bin:/usr/bin:/bin" \
  ASTRA_REVIEW_DIFF_PATH=tracked.txt ASTRA_REVIEW_EFFORT=xhigh \
  CAPTURE_ARGS="$test_home/astra-scoped.args" \
  CAPTURE_STDIN="$test_home/astra-scoped.stdin" \
  "$astra_helper" "Review only." >/dev/null
grep -qxF 'model_reasoning_effort="xhigh"' "$test_home/astra-scoped.args"
grep -qF "=== git diff HEAD -- tracked.txt ===" "$test_home/astra-scoped.stdin"
if grep -qF "unrelated-astra.txt" "$test_home/astra-scoped.stdin"; then
  printf '%s\n' "Scoped Astra review leaked an unrelated path." >&2
  exit 1
fi
rm unrelated-astra.txt

for invalid_setting in \
  ASTRA_REVIEW_MODEL=gpt-5.6-sol \
  ASTRA_REVIEW_MODEL=astra \
  ASTRA_REVIEW_EFFORT=ultra \
  ASTRA_REVIEW_EFFORT=invalid \
  ASTRA_REVIEW_MODE=invalid \
  ASTRA_REVIEW_DIFF_PATH=../tracked.txt \
  ASTRA_REVIEW_DIFF_PATH=/tmp/tracked.txt \
  ASTRA_REVIEW_MAX_DIFF_BYTES=0 \
  ASTRA_REVIEW_MAX_DIFF_BYTES=1; do
  if env PATH="$fake_bin:/usr/bin:/bin" "$invalid_setting" \
    CAPTURE_ARGS="$test_home/astra-invalid.args" \
    CAPTURE_STDIN="$test_home/astra-invalid.stdin" \
    "$astra_helper" "Review only." \
    >"$test_home/astra-invalid.stdout" 2>"$test_home/astra-invalid.stderr"; then
    printf 'Expected Astra setting to fail closed: %s\n' "$invalid_setting" >&2
    exit 1
  fi
  grep -qF "Astra review unavailable:" "$test_home/astra-invalid.stderr"
  test ! -e "$test_home/astra-invalid.args"
done

# A renamed shared helper must not silently drop Astra's model or path scope.
cp "$astra_helper" "$fake_bin/unknown-review"
if PATH="$fake_bin:/usr/bin:/bin" ASTRA_REVIEW_DIFF_PATH=tracked.txt \
  CAPTURE_ARGS="$test_home/unknown-review.args" \
  CAPTURE_STDIN="$test_home/unknown-review.stdin" \
  "$fake_bin/unknown-review" "Review only." \
  >"$test_home/unknown-review.stdout" 2>"$test_home/unknown-review.stderr"; then
  printf '%s\n' "Expected an unknown helper name to fail closed." >&2
  exit 1
fi
grep -qF "invoke as sol-review or astra-review" "$test_home/unknown-review.stderr"
test ! -e "$test_home/unknown-review.args"

for invalid_effort in ultra invalid; do
  if PATH="$fake_bin:/usr/bin:/bin" SOL_REVIEW_EFFORT="$invalid_effort" \
    CAPTURE_ARGS="$test_home/sol-invalid-effort.args" \
    CAPTURE_STDIN="$test_home/sol-invalid-effort.stdin" \
    "$test_home/.local/bin/sol-review" "Review only." \
    >"$test_home/sol-invalid-effort.stdout" 2>"$test_home/sol-invalid-effort.stderr"; then
    printf '%s\n' "Expected invalid Sol effort to fail closed." >&2
    exit 1
  fi
  grep -qF "SOL_REVIEW_EFFORT must be" "$test_home/sol-invalid-effort.stderr"
  test ! -e "$test_home/sol-invalid-effort.args"
done

# An unavailable model must preserve the failure, with no hidden fallback call.
astra_status=0
PATH="$fake_bin:/usr/bin:/bin" FAKE_CODEX_STATUS=42 \
  CAPTURE_CALLS="$test_home/astra-failure.calls" \
  CAPTURE_ARGS="$test_home/astra-failure.args" \
  CAPTURE_STDIN="$test_home/astra-failure.stdin" \
  "$astra_helper" "Review only." >/dev/null || astra_status=$?
test "$astra_status" -eq 42
test "$(wc -l <"$test_home/astra-failure.calls")" -eq 1
grep -qxF "gpt-6-astra" "$test_home/astra-failure.args"

git checkout -- tracked.txt
if PATH="$fake_bin:/usr/bin:/bin" \
  CAPTURE_ARGS="$test_home/astra-empty.args" \
  CAPTURE_STDIN="$test_home/astra-empty.stdin" \
  "$astra_helper" "Review only." \
  >"$test_home/astra-empty.stdout" 2>"$test_home/astra-empty.stderr"; then
  printf '%s\n' "Expected an empty Astra review to fail closed." >&2
  exit 1
fi
grep -qF "Set ASTRA_REVIEW_MODE=audit" "$test_home/astra-empty.stderr"
test ! -e "$test_home/astra-empty.args"

PATH="$fake_bin:/usr/bin:/bin" ASTRA_REVIEW_MODE=audit ASTRA_REVIEW_EFFORT=max \
  CAPTURE_ARGS="$test_home/astra-audit.args" \
  CAPTURE_STDIN="$test_home/astra-audit.stdin" \
  "$astra_helper" "Audit only." >/dev/null
grep -qxF 'model_reasoning_effort="max"' "$test_home/astra-audit.args"
grep -qF "=== git diff HEAD ===" "$test_home/astra-audit.stdin"

printf '%s\n' "All orchestration tests passed."
