#!/usr/bin/env bash

set -euo pipefail

status=0
packages=("$@")

run_check() {
  local name
  name=$1
  shift
  printf '\n==> %s\n' "$name"
  if "$@"; then
    printf '[PASS] %s\n' "$name"
  else
    printf '[FAIL] %s\n' "$name" >&2
    status=1
  fi
}

# Functions below are passed by name to run_check.
# shellcheck disable=SC2329
check_stow() {
  local output stow_status
  set +e
  output=$(stow --simulate --verbose --no-folding --dir=packages --target="$HOME" "${packages[@]}" 2>&1)
  stow_status=$?
  set -e
  [ -z "$output" ] || printf '%s\n' "$output"
  [ "$stow_status" -eq 0 ] || return "$stow_status"
  if printf '%s\n' "$output" | grep -Eq '^(LINK|MKDIR):'; then
    printf 'Stow would create links or directories.\n' >&2
    return 1
  fi
}

# shellcheck disable=SC2329
check_gh_extensions() {
  local output
  output=$(gh extension list)
  printf '%s\n' "$output" | grep -Fq 'dlvhdr/gh-dash' &&
    printf '%s\n' "$output" | grep -Fq 'babarot/gh-infra'
}

run_check "Homebrew dependencies" brew bundle check --verbose --file=Brewfile
run_check "Stow links" check_stow
run_check "zsh syntax" zsh -n packages/zsh/.zshrc
run_check "mise installation" mise doctor
run_check "GitHub CLI extensions" check_gh_extensions
run_check "GitAlias" test -f "$HOME/.git-extensions/gitalias.txt"
run_check "Vim plugins" test -d "$HOME/.vim/pack/themes/start/iceberg.vim"
run_check "bat theme cache" sh -c 'bat --list-themes | grep -Fxq Iceberg'

printf '\n'
if [ "$status" -eq 0 ]; then
  printf 'All checks passed.\n'
else
  printf 'One or more checks failed.\n' >&2
fi
exit "$status"
