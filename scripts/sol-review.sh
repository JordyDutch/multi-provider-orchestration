#!/bin/sh

set -eu

case "$(basename "$0")" in
  astra-review|astra-review.sh)
    reviewer="Astra"
    env_prefix="ASTRA_REVIEW"
    model="${ASTRA_REVIEW_MODEL:-gpt-6-astra}"
    effort="${ASTRA_REVIEW_EFFORT:-high}"
    review_mode="${ASTRA_REVIEW_MODE:-review}"
    diff_path="${ASTRA_REVIEW_DIFF_PATH:-}"
    max_diff_bytes="${ASTRA_REVIEW_MAX_DIFF_BYTES:-200000}"
    if [ "$model" != "gpt-6-astra" ]; then
      echo "Astra review unavailable: model must be pinned to gpt-6-astra." >&2
      exit 64
    fi
    ;;
  sol-review|sol-review.sh)
    reviewer="Sol"
    env_prefix="SOL_REVIEW"
    model="${SOL_REVIEW_MODEL:-gpt-5.6-sol}"
    effort="${SOL_REVIEW_EFFORT:-xhigh}"
    review_mode="${SOL_REVIEW_MODE:-review}"
    diff_path="${SOL_REVIEW_DIFF_PATH:-}"
    max_diff_bytes="${SOL_REVIEW_MAX_DIFF_BYTES:-200000}"
    ;;
  *)
    echo "Codex review unavailable: invoke as sol-review or astra-review (optionally with .sh)." >&2
    exit 64
    ;;
esac
prompt="${*:-Review the current change adversarially for concrete bugs, regressions, and missing tests. Return findings ordered by severity with file and line evidence. Do not edit files.}"
role_preamble="You are a bounded independent reviewer in a Claude-led workflow. The calling orchestrator retains final integration and synthesis ownership. Do not edit files, widen the task, or claim final ownership."

case "$effort" in
  low|medium|high|xhigh|max)
    ;;
  *)
    echo "$reviewer review unavailable: ${env_prefix}_EFFORT must be low, medium, high, xhigh, or max; ultra is not allowed in review hand-offs." >&2
    exit 64
    ;;
esac

case "$review_mode" in
  review|audit)
    ;;
  *)
    echo "$reviewer review unavailable: ${env_prefix}_MODE must be review or audit." >&2
    exit 64
    ;;
esac

if [ -n "$diff_path" ]; then
  case "$diff_path" in
    /*|..|../*|*/..|*/../*)
      echo "$reviewer review unavailable: ${env_prefix}_DIFF_PATH must be a relative path without parent traversal." >&2
      exit 64
      ;;
  esac
fi

case "$max_diff_bytes" in
  ''|*[!0-9]*|0)
    echo "$reviewer review unavailable: ${env_prefix}_MAX_DIFF_BYTES must be a positive integer." >&2
    exit 64
    ;;
esac

codex_bin="$(command -v codex 2>/dev/null || true)"
if [ -z "$codex_bin" ] && [ -x "$HOME/.local/bin/codex" ]; then
  codex_bin="$HOME/.local/bin/codex"
fi

if [ -z "$codex_bin" ]; then
  echo "$reviewer review unavailable: the codex CLI is not on PATH." >&2
  echo "Install Codex, then run: codex login" >&2
  exit 127
fi

if ! "$codex_bin" login status >/dev/null 2>&1; then
  echo "$reviewer review unavailable: Codex is not authenticated." >&2
  echo "Run: $codex_bin login" >&2
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "$reviewer review unavailable: the current directory is not a Git worktree." >&2
  exit 3
fi

review_tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
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
  echo "$reviewer review unavailable: no tracked or untracked changes found in the selected scope. Set ${env_prefix}_MODE=audit for an intentional clean-tree audit." >&2
  exit 4
fi

diff_bytes="$(wc -c <"$diff_file" | tr -d '[:space:]')"
status_bytes="$(printf '%s\n' "$review_status" | wc -c | tr -d '[:space:]')"
evidence_bytes="$((diff_bytes + status_bytes))"
if [ "$evidence_bytes" -gt "$max_diff_bytes" ]; then
  echo "$reviewer review unavailable: review evidence is $evidence_bytes bytes, above ${env_prefix}_MAX_DIFF_BYTES=$max_diff_bytes. Scope it with ${env_prefix}_DIFF_PATH or raise the explicit limit." >&2
  exit 5
fi

echo "Running read-only $reviewer review with $model at $effort effort..." >&2

{
  printf '%s\n\n' "$role_preamble"
  printf '%s\n\n' "$prompt"
  printf '%s\n' \
    "The repository evidence below was captured by the read-only wrapper." \
    "Untracked paths appear in status but not in Git diffs; inspect them read-only." \
    "Do not edit files." \
    "" \
    "=== git status --short --branch ==="
  printf '%s\n' "$review_status"
  if [ -n "$diff_path" ]; then
    printf '%s\n' "" "=== $diff_label -- $diff_path ==="
  else
    printf '%s\n' "" "=== $diff_label ==="
  fi
  cat "$diff_file"
} | "$codex_bin" exec \
    --model "$model" \
    --config "model_reasoning_effort=\"$effort\"" \
    --sandbox read-only \
    --ephemeral \
    -
