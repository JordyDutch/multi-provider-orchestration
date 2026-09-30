#!/bin/sh

set -eu
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/test-setup-refresh.XXXXXX")"
cleanup() { rm -rf "$test_dir"; }
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

setup_repo="$test_dir/setup"
mkdir -p "$setup_repo/scripts" "$test_dir/bin" "$test_dir/state"
git_bin="$(command -v git)"
export REAL_REFRESH_GIT="$git_bin"
export REFRESH_CALLS="$test_dir/calls"
cat >"$test_dir/bin/git" <<'EOF'
#!/bin/sh
if [ "$1" = -C ] && [ "$3" = fetch ]; then
  printf '%s\n' fetch >>"$REFRESH_CALLS"
  exit 0
fi
exec "$REAL_REFRESH_GIT" "$@"
EOF
cat >"$setup_repo/scripts/test.sh" <<'EOF'
#!/bin/sh
printf '%s\n' tests >>"$REFRESH_CALLS"
exit "${FAKE_REFRESH_TEST_STATUS:-0}"
EOF
cat >"$setup_repo/scripts/install-global.sh" <<'EOF'
#!/bin/sh
printf '%s\n' install >>"$REFRESH_CALLS"
if [ "${FAKE_REFRESH_REAL_INSTALL:-no}" = yes ]; then
  exec "$REAL_REFRESH_INSTALLER"
fi
exit "${FAKE_REFRESH_INSTALL_STATUS:-0}"
EOF
chmod +x "$test_dir/bin/git" "$setup_repo/scripts/test.sh" "$setup_repo/scripts/install-global.sh"
git -c init.templateDir= -C "$setup_repo" init -q
git -C "$setup_repo" add scripts/test.sh scripts/install-global.sh
git -C "$setup_repo" -c commit.gpgsign=false \
  -c user.name='Orchestration Tests' -c user.email=tests@example.invalid \
  commit -qm 'Add refresh fixture'
git -C "$setup_repo" update-ref refs/remotes/origin/main HEAD
canonical_url=https://github.com/JordyDutch/multi-provider-orchestration
git -C "$setup_repo" remote add origin "$canonical_url"

export PATH="$test_dir/bin:/usr/bin:/bin"
export CODEX_SETUP_REPO="$setup_repo"
export CODEX_SETUP_STATE_DIR="$test_dir/state"
export SETUP_REFRESH_DATE=2099-02-01
stamp="$CODEX_SETUP_STATE_DIR/multi-provider-orchestration-refresh-date"

for valid_url in "$canonical_url" "$canonical_url.git"; do
  git -C "$setup_repo" remote set-url origin "$valid_url"
  rm -f "$stamp" "$REFRESH_CALLS"
  "$script_dir/refresh-global-setup.sh" >"$test_dir/out" 2>"$test_dir/err"
  test "$(cat "$stamp")" = "$SETUP_REFRESH_DATE"
  test "$(cat "$REFRESH_CALLS")" = "$(printf 'fetch\ntests\ninstall')"
done

for invalid_url in "$canonical_url.git/" "$canonical_url-extra" \
  'https://github.com/elsewhere/multi-provider-orchestration' \
  'git@github.com:JordyDutch/multi-provider-orchestration.git'; do
  git -C "$setup_repo" remote set-url origin "$invalid_url"
  rm -f "$stamp" "$REFRESH_CALLS"
  refresh_status=0
  "$script_dir/refresh-global-setup.sh" >"$test_dir/out" 2>"$test_dir/err" || refresh_status=$?
  test "$refresh_status" -eq 3
  test ! -e "$stamp"
  test ! -e "$REFRESH_CALLS"
done

git -C "$setup_repo" remote set-url origin "$canonical_url.git"
git -C "$setup_repo" config status.showUntrackedFiles no
touch "$setup_repo/new-file"
refresh_status=0
"$script_dir/refresh-global-setup.sh" >"$test_dir/out" 2>"$test_dir/err" || refresh_status=$?
test "$refresh_status" -eq 2
test ! -e "$stamp"
test ! -e "$REFRESH_CALLS"
rm -f "$setup_repo/new-file"

for failing_step in tests install; do
  rm -f "$stamp" "$REFRESH_CALLS"
  refresh_status=0
  if [ "$failing_step" = tests ]; then
    FAKE_REFRESH_TEST_STATUS=23 "$script_dir/refresh-global-setup.sh" \
      >"$test_dir/out" 2>"$test_dir/err" || refresh_status=$?
    test "$(cat "$REFRESH_CALLS")" = "$(printf 'fetch\ntests')"
  else
    FAKE_REFRESH_INSTALL_STATUS=23 "$script_dir/refresh-global-setup.sh" \
      >"$test_dir/out" 2>"$test_dir/err" || refresh_status=$?
    test "$(cat "$REFRESH_CALLS")" = "$(printf 'fetch\ntests\ninstall')"
  fi
  test "$refresh_status" -eq 23
  test ! -e "$stamp"
done

# Exercise the real installer's exit status through refresh, with an isolated
# home and controlled login-shell results. Failed checks must retain yesterday.
export REAL_REFRESH_INSTALLER="$script_dir/install-global.sh"
cat >"$test_dir/login-shell" <<'EOF'
#!/bin/sh
test "$#" -eq 2 && test "$1" = -lic || exit 64
if [ "$2" = "command -v ${FAKE_MISSING_HELPER:-}" ]; then exit 1; fi
if [ "${FAKE_LOGIN_MODE:-ready}" = shadowed ] && [ "$2" = 'command -v sol-review' ]; then
  printf '%s\n' '/shadowed/sol-review'
  exit 0
fi
PATH="$HOME/.local/bin:/usr/bin:/bin" /bin/sh -c "$2" || exit 1
if [ "${FAKE_LOGIN_MODE:-ready}" = nonzero ]; then exit 23; fi
EOF
chmod +x "$test_dir/login-shell"

for failing_check in claude-review fable-review opus-task fable-task sonnet-task \
  sol-review astra-review refresh-global-setup shadowed nonzero unavailable-shell; do
  printf '%s\n' '2099-01-31' >"$stamp"
  rm -f "$REFRESH_CALLS"
  fixture_shell="$test_dir/login-shell"
  if [ "$failing_check" = unavailable-shell ]; then fixture_shell="$test_dir/missing-shell"; fi
  refresh_status=0
  HOME="$test_dir/install-home" SHELL="$fixture_shell" \
    FAKE_REFRESH_REAL_INSTALL=yes FAKE_MISSING_HELPER="$failing_check" \
    FAKE_LOGIN_MODE="$failing_check" "$script_dir/refresh-global-setup.sh" \
    >"$test_dir/out" 2>"$test_dir/err" || refresh_status=$?
  test "$refresh_status" -eq 5
  test "$(cat "$stamp")" = '2099-01-31'
  grep -qF 'fresh-shell helper verification failed' "$test_dir/err"
  test "$(cat "$REFRESH_CALLS")" = "$(printf 'fetch\ntests\ninstall')"
done

HOME="$test_dir/install-home" SHELL="$test_dir/login-shell" \
  FAKE_REFRESH_REAL_INSTALL=yes "$script_dir/refresh-global-setup.sh" \
  >"$test_dir/out" 2>"$test_dir/err"
test "$(cat "$stamp")" = "$SETUP_REFRESH_DATE"
cmp -s "$script_dir/claude-review.sh" "$test_dir/install-home/.local/bin/claude-review"

printf '%s\n' 'Setup refresh tests passed.'
