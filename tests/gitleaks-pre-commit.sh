#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
hook_path="$repo_root/packages/git/.git-hooks"
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

command -v gitleaks >/dev/null 2>&1 || fail 'gitleaks is not installed'

git init -q "$test_root/repository"
git -C "$test_root/repository" config user.name 'Gitleaks Hook Test'
git -C "$test_root/repository" config user.email 'gitleaks-hook-test@example.com'

local_hook="$test_root/repository/.git/hooks/pre-commit"
local_hook_marker="$test_root/local-hook-ran"
cat >"$local_hook" <<EOF
#!/usr/bin/env bash
printf 'ran\n' >>'$local_hook_marker'
EOF
chmod +x "$local_hook"

printf 'safe content\n' >"$test_root/repository/example.txt"
git -C "$test_root/repository" add example.txt
git -C "$test_root/repository" -c core.hooksPath="$hook_path" \
  commit -q -m 'test: allow safe commit' || fail 'safe commit was rejected'
[ "$(wc -l <"$local_hook_marker")" -eq 1 ] || fail 'repo-local hook was not delegated to'

dummy_secret=$(printf '%s%s' 'ghp_' 'Zx7Qa2Wm9Lp4Ks8Hd3Jf6Ng1Bc5Vr0TyUiEo')
printf 'token = "%s"\n' "$dummy_secret" >"$test_root/repository/secret.txt"
git -C "$test_root/repository" add secret.txt
if output=$(git -C "$test_root/repository" -c core.hooksPath="$hook_path" \
  commit -m 'test: reject secret' 2>&1); then
  fail 'commit containing a known-format dummy secret was accepted'
fi
case "$output" in
  *"$dummy_secret"*) fail 'gitleaks output exposed the detected secret' ;;
esac
[ "$(wc -l <"$local_hook_marker")" -eq 1 ] || fail 'repo-local hook ran after gitleaks failed'
git -C "$test_root/repository" diff --cached --quiet -- secret.txt && \
  fail 'rejected secret was not left staged'

printf 'Gitleaks pre-commit hook tests passed.\n'
