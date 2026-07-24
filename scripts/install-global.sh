#!/bin/sh

set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(dirname "$script_dir")"
codex_dir="$HOME/.codex"
claude_dir="$HOME/.claude"
local_bin_dir="$HOME/.local/bin"
claude_rules="$claude_dir/CLAUDE.md"
shared_import='@~/.codex/AGENTS.md'

backup_if_different() {
  source_file="$1"
  target_file="$2"

  if [ -f "$target_file" ] && ! cmp -s "$source_file" "$target_file"; then
    backup_file="$target_file.backup.$(date +%Y%m%d%H%M%S).$$"
    cp -p "$target_file" "$backup_file"
    printf 'Backed up %s to %s\n' "$target_file" "$backup_file"
  fi
}

verify_copy() {
  source_file="$1"
  target_file="$2"

  if ! cmp -s "$source_file" "$target_file"; then
    printf 'Verification failed: %s differs from %s\n' \
      "$target_file" "$source_file" >&2
    exit 4
  fi
}

mkdir -p "$codex_dir" "$claude_dir" "$local_bin_dir"

backup_if_different "$repo_dir/AGENTS.md" "$codex_dir/AGENTS.md"
backup_if_different \
  "$repo_dir/ORCHESTRATION.md" "$codex_dir/ORCHESTRATION.md"
backup_if_different \
  "$repo_dir/scripts/claude-review.sh" "$local_bin_dir/claude-review"
backup_if_different \
  "$repo_dir/scripts/claude-review.sh" "$local_bin_dir/fable-review"
backup_if_different \
  "$repo_dir/scripts/sol-review.sh" "$local_bin_dir/sol-review"

install -m 644 "$repo_dir/AGENTS.md" "$codex_dir/AGENTS.md"
install -m 644 "$repo_dir/ORCHESTRATION.md" "$codex_dir/ORCHESTRATION.md"
install -m 755 "$repo_dir/scripts/claude-review.sh" \
  "$local_bin_dir/claude-review"
install -m 755 "$repo_dir/scripts/claude-review.sh" \
  "$local_bin_dir/fable-review"
install -m 755 "$repo_dir/scripts/sol-review.sh" \
  "$local_bin_dir/sol-review"

touch "$claude_rules"
if ! grep -qxF "$shared_import" "$claude_rules"; then
  printf '\n%s\n' "$shared_import" >>"$claude_rules"
fi

verify_copy "$repo_dir/AGENTS.md" "$codex_dir/AGENTS.md"
verify_copy "$repo_dir/ORCHESTRATION.md" "$codex_dir/ORCHESTRATION.md"
verify_copy \
  "$repo_dir/scripts/claude-review.sh" "$local_bin_dir/claude-review"
verify_copy \
  "$repo_dir/scripts/claude-review.sh" "$local_bin_dir/fable-review"
verify_copy "$repo_dir/scripts/sol-review.sh" "$local_bin_dir/sol-review"
test "$(grep -c -xF "$shared_import" "$claude_rules")" -eq 1

printf '%s\n' \
  "Installed the shared Codex and Claude baseline:" \
  "  $codex_dir/AGENTS.md" \
  "  $codex_dir/ORCHESTRATION.md" \
  "  $local_bin_dir/claude-review" \
  "  $local_bin_dir/fable-review" \
  "  $local_bin_dir/sol-review" \
  "Claude import preserved in $claude_rules"

fresh_helper=''
if [ -n "${SHELL:-}" ] && [ -x "$SHELL" ]; then
  fresh_helper="$("$SHELL" -lic 'command -v claude-review' 2>/dev/null || true)"
fi

if [ "$fresh_helper" = "$local_bin_dir/claude-review" ]; then
  printf 'Fresh shell resolves claude-review at %s\n' "$fresh_helper"
else
  printf '%s\n' \
    "Warning: a fresh shell does not resolve $local_bin_dir/claude-review." \
    "Add $local_bin_dir to PATH in your shell configuration." >&2
fi

fresh_fable=''
if [ -n "${SHELL:-}" ] && [ -x "$SHELL" ]; then
  fresh_fable="$("$SHELL" -lic 'command -v fable-review' 2>/dev/null || true)"
fi

if [ "$fresh_fable" = "$local_bin_dir/fable-review" ]; then
  printf 'Fresh shell resolves fable-review at %s\n' "$fresh_fable"
else
  printf '%s\n' \
    "Warning: a fresh shell does not resolve $local_bin_dir/fable-review." \
    "Add $local_bin_dir to PATH in your shell configuration." >&2
fi

fresh_sol=''
if [ -n "${SHELL:-}" ] && [ -x "$SHELL" ]; then
  fresh_sol="$("$SHELL" -lic 'command -v sol-review' 2>/dev/null || true)"
fi

if [ "$fresh_sol" = "$local_bin_dir/sol-review" ]; then
  printf 'Fresh shell resolves sol-review at %s\n' "$fresh_sol"
else
  printf '%s\n' \
    "Warning: a fresh shell does not resolve $local_bin_dir/sol-review." \
    "Add $local_bin_dir to PATH in your shell configuration." >&2
fi
