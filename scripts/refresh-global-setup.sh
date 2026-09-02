#!/bin/sh

set -eu

setup_repo="${CODEX_SETUP_REPO:-$HOME/GITHUB/multi-provider-orchestration}"
state_dir="${CODEX_SETUP_STATE_DIR:-$HOME/.codex}"
stamp_file="$state_dir/multi-provider-orchestration-refresh-date"
today="${SETUP_REFRESH_DATE:-$(date +%F)}"

if [ "${SETUP_REFRESH_FORCE:-0}" != "1" ] && [ -f "$stamp_file" ] && \
  [ "$(cat "$stamp_file")" = "$today" ]; then
  printf '%s\n' "Global setup already refreshed for $today."
  exit 0
fi

if [ ! -d "$setup_repo/.git" ]; then
  printf '%s\n' \
    "Global setup refresh blocked: canonical repository is missing at $setup_repo." \
    "Clone https://github.com/JordyDutch/multi-provider-orchestration there or set CODEX_SETUP_REPO." >&2
  exit 1
fi

if [ -n "$(git -C "$setup_repo" status --porcelain)" ]; then
  printf '%s\n' \
    "Global setup refresh blocked: $setup_repo has uncommitted changes." \
    "Commit, stash, or use a separate clean canonical checkout; no files were changed." >&2
  exit 2
fi

remote_url="$(git -C "$setup_repo" remote get-url origin 2>/dev/null || true)"
if [ "$remote_url" != "https://github.com/JordyDutch/multi-provider-orchestration" ]; then
  printf '%s\n' \
    "Global setup refresh blocked: origin must be https://github.com/JordyDutch/multi-provider-orchestration." >&2
  exit 3
fi

git -C "$setup_repo" fetch --quiet origin main

local_head="$(git -C "$setup_repo" rev-parse HEAD)"
remote_head="$(git -C "$setup_repo" rev-parse origin/main)"
merge_base="$(git -C "$setup_repo" merge-base HEAD origin/main)"

if [ "$local_head" = "$remote_head" ]; then
  printf '%s\n' "Global setup is already current at $local_head."
elif [ "$merge_base" = "$local_head" ]; then
  git -C "$setup_repo" merge --ff-only origin/main
  printf '%s\n' "Fast-forwarded global setup to $remote_head."
else
  printf '%s\n' \
    "Global setup refresh blocked: canonical checkout is not behind origin/main." \
    "Use a clean checkout at origin/main; no files were changed." >&2
  exit 4
fi

"$setup_repo/scripts/test.sh"
"$setup_repo/scripts/install-global.sh"

mkdir -p "$state_dir"
printf '%s\n' "$today" >"$stamp_file"
printf '%s\n' "Global setup refresh completed for $today."
