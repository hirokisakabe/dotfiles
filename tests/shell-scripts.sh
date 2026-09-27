#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
bin_dir="$test_root/bin"
mkdir -p "$bin_dir"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  case "$1" in *"$2"*) ;; *) fail "expected output to contain: $2" ;; esac
}

test_skills_install() {
  local home output
  home="$test_root/skills-home"
  mkdir -p "$home/.codex/skills"
  cat >"$bin_dir/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
repository=$3
skill_source=$4
skill=${skill_source##*/}
directory=$6
case "$skill_source" in
  */*) skill_path="$skill_source" ;;
  *) skill_path="skills/$skill_source" ;;
esac
mkdir -p "$directory/$skill"
cat >"$directory/$skill/SKILL.md" <<SKILL
---
metadata:
    github-repo: https://github.com/$repository
    github-path: $skill_path
    github-tree-sha: 0123456789abcdef0123456789abcdef01234567
---
SKILL
EOF
  chmod +x "$bin_dir/gh"

  make -s -C "$repo_root" skills-install \
    HOME="$home" PATH="$bin_dir:$PATH" \
    AGENT_SKILLS='owner/repo:example owner/repo:collection/skills/nested-example' \
    AGENT_SKILLS_DIR="$home/.agents/skills" \
    CLAUDE_SKILLS_DIR="$home/.claude/skills" \
    CODEX_SKILLS_DIR="$home/.codex/skills"
  [ -f "$home/.agents/skills/example/SKILL.md" ] || fail 'skill was not installed'
  [ -f "$home/.agents/skills/nested-example/SKILL.md" ] || fail 'nested skill was not installed'
  [ -L "$home/.claude/skills/example" ] || fail 'Claude skill link was not created'
  [ -L "$home/.claude/skills/nested-example" ] || fail 'nested Claude skill link was not created'

  HOME="$home" PATH="$bin_dir:$PATH" \
    AGENT_SKILLS_DIR="$home/.agents/skills" \
    CLAUDE_SKILLS_DIR="$home/.claude/skills" \
    CODEX_SKILLS_DIR="$home/.codex/skills" \
    "$repo_root/scripts/skills-install.sh" owner/repo:collection/skills/nested-example

  mkdir -p "$home/.agents/skills/unmanaged"
  printf 'unmanaged\n' >"$home/.agents/skills/unmanaged/SKILL.md"
  if output=$(HOME="$home" PATH="$bin_dir:$PATH" \
    AGENT_SKILLS_DIR="$home/.agents/skills" \
    CLAUDE_SKILLS_DIR="$home/.claude/skills" \
    CODEX_SKILLS_DIR="$home/.codex/skills" \
    "$repo_root/scripts/skills-install.sh" owner/repo:unmanaged 2>&1); then
    fail 'unmanaged skill collision was accepted'
  fi
  assert_contains "$output" '管理外の既存 skill と競合しています'
}

write_fake_codex() {
  cat >"$bin_dir/codex" <<'EOF'
#!/usr/bin/env bash
cat <<'JSON'
{"checks":{"config.load":{"status":"ok","details":{"model":"test-model","feature flag overrides":""}},"sandbox.helpers":{"details":{"approval policy":"OnRequest","filesystem sandbox":"workspace-write"}}}}
JSON
EOF
  chmod +x "$bin_dir/codex"
}

write_minimal_codex_config() {
  printf '%s\n' 'model_reasoning_effort = "medium"' '' '[tui]' 'status_line = ["model-with-reasoning"]' >"$1"
}

assert_codex_config_rejected() {
  local destination output source
  source=$1
  destination=$2
  if output=$(PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$source" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' \
    "$repo_root/scripts/codex-system-config.sh" check 2>&1); then
    fail 'shared Codex config accepted an unrelated override'
  fi
  assert_contains "$output" '以外を追加しないでください'
}

test_codex_system_config() {
  local case_dir source destination missing_source output target
  case_dir="$test_root/codex"
  source="$case_dir/shared.toml"
  destination="$case_dir/etc/config.toml"
  mkdir -p "$case_dir"
  write_minimal_codex_config "$source"
  write_fake_codex

  output=$(PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$source" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' \
    "$repo_root/scripts/codex-system-config.sh" dry-run)
  assert_contains "$output" '新規作成予定'
  make -s -C "$repo_root" codex-system-config-install \
    PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$source" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' >/dev/null
  cmp -s "$source" "$destination" || fail 'system config was not installed'
  PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$source" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' \
    "$repo_root/scripts/codex-system-config.sh" check >/dev/null

  printf '%s\n' 'sandbox_mode = "danger-full-access"' >>"$source"
  assert_codex_config_rejected "$source" "$destination"
  if output=$(PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$source" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' \
    "$repo_root/scripts/codex-system-config.sh" install 2>&1); then
    fail 'install accepted an unrelated Codex override'
  fi
  assert_contains "$output" '以外を追加しないでください'
  if output=$(PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$source" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' \
    "$repo_root/scripts/codex-system-config.sh" verify 2>&1); then
    fail 'verify accepted an unrelated Codex override'
  fi
  assert_contains "$output" '以外を追加しないでください'

  printf '%s\n' '"model" = "test"' 'model_reasoning_effort = "medium"' '' '[tui]' 'status_line = ["model-with-reasoning"]' >"$source"
  assert_codex_config_rejected "$source" "$destination"

  printf '%s\n' 'model_reasoning_effort = "medium"' 'tui.status_line = ["model-with-reasoning"]' 'tui.extra = true' >"$source"
  assert_codex_config_rejected "$source" "$destination"

  printf '%s\n' 'extra = { enabled = true }' 'model_reasoning_effort = "medium"' '' '[tui]' 'status_line = ["model-with-reasoning"]' >"$source"
  assert_codex_config_rejected "$source" "$destination"

  write_minimal_codex_config "$source"

  PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$source" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' \
    "$repo_root/scripts/codex-system-config.sh" verify >/dev/null

  target="$case_dir/symlink-target.toml"
  printf 'do not change\n' >"$target"
  rm -f "$destination"
  ln -s "$target" "$destination"
  if output=$(PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$source" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' \
    "$repo_root/scripts/codex-system-config.sh" install 2>&1); then
    fail 'system config symlink was accepted'
  fi
  assert_contains "$output" 'symlink は自動処理しません'
  [ "$(cat "$target")" = 'do not change' ] || fail 'symlink target was modified'

  rm -f "$destination"
  missing_source="$case_dir/missing.toml"
  if output=$(PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$missing_source" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' \
    "$repo_root/scripts/codex-system-config.sh" install 2>&1); then
    fail 'install with a missing source was accepted'
  fi
  case "$output" in
    *'unbound variable'*) fail 'cleanup replaced the original install error' ;;
  esac
  if find "$(dirname "$destination")" -name '.config.toml.install.*' -print -quit | grep -q .; then
    fail 'failed install left a temporary file behind'
  fi

  PATH="$bin_dir:$PATH" CODEX_SHARED_CONFIG="$repo_root/config/codex/config.toml" \
    CODEX_SYSTEM_CONFIG="$destination" CODEX_CONFIG_SUDO='' \
    "$repo_root/scripts/codex-system-config.sh" check >/dev/null
}

write_doctor_mocks() {
  local command
  for command in brew zsh mise; do
    cat >"$bin_dir/$command" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$bin_dir/$command"
  done
  cat >"$bin_dir/bat" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' Iceberg
EOF
  cat >"$bin_dir/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'dlvhdr/gh-dash' 'babarot/gh-infra'
EOF
  cat >"$bin_dir/stow" <<'EOF'
#!/usr/bin/env bash
[ "${STOW_CHANGES-}" != 1 ] || printf '%s\n' 'LINK: .example'
EOF
  chmod +x "$bin_dir/bat" "$bin_dir/gh" "$bin_dir/stow"
}

test_doctor() {
  local home output
  home="$test_root/doctor-home"
  mkdir -p "$home/.git-extensions" "$home/.vim/pack/themes/start/iceberg.vim"
  : >"$home/.git-extensions/gitalias.txt"
  write_doctor_mocks

  output=$(make -s -C "$repo_root" doctor HOME="$home" PATH="$bin_dir:$PATH" PACKAGES=zsh)
  assert_contains "$output" 'All checks passed.'
  if output=$(cd "$repo_root" && HOME="$home" PATH="$bin_dir:$PATH" STOW_CHANGES=1 ./scripts/doctor.sh zsh 2>&1); then
    fail 'doctor accepted pending Stow changes'
  fi
  assert_contains "$output" '[FAIL] Stow links'
}

test_skills_install
test_codex_system_config
test_doctor
printf 'All shell script tests passed.\n'
