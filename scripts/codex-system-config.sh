#!/usr/bin/env bash

set -euo pipefail

: "${CODEX_SHARED_CONFIG:?CODEX_SHARED_CONFIG is required}"
: "${CODEX_SYSTEM_CONFIG:?CODEX_SYSTEM_CONFIG is required}"

CODEX_CONFIG_SUDO=${CODEX_CONFIG_SUDO-sudo}

privileged() {
  if [ -n "$CODEX_CONFIG_SUDO" ]; then
    # Preserve Makefile's support for a command plus fixed arguments.
    # shellcheck disable=SC2086
    $CODEX_CONFIG_SUDO "$@"
  else
    "$@"
  fi
}

reject_destination_symlink() {
  if privileged test -L "$CODEX_SYSTEM_CONFIG"; then
    printf '%s\n' "symlink は自動処理しません: $CODEX_SYSTEM_CONFIG" >&2
    exit 1
  fi
}

dry_run() {
  local tmp_file
  umask 077
  reject_destination_symlink
  if privileged test -e "$CODEX_SYSTEM_CONFIG"; then
    tmp_file=$(mktemp)
    trap 'rm -f "$tmp_file"' EXIT HUP INT TERM
    privileged cat "$CODEX_SYSTEM_CONFIG" >"$tmp_file"
    if cmp -s "$tmp_file" "$CODEX_SHARED_CONFIG"; then
      printf '%s\n' "変更はありません: $CODEX_SYSTEM_CONFIG"
    else
      printf '%s\n' "適用予定の差分: $CODEX_SYSTEM_CONFIG"
      diff -u "$tmp_file" "$CODEX_SHARED_CONFIG" || true
    fi
    rm -f "$tmp_file"
    trap - EXIT HUP INT TERM
  else
    printf '%s\n' "新規作成予定: $CODEX_SYSTEM_CONFIG"
    sed -n '1,$p' "$CODEX_SHARED_CONFIG"
  fi
}

install_config() {
  local destination_dir tmp_file current_file answer
  umask 077
  destination_dir=$(dirname "$CODEX_SYSTEM_CONFIG")
  tmp_file=''
  current_file=''
  cleanup_install() {
    [ -z "$current_file" ] || rm -f "$current_file"
    [ -z "$tmp_file" ] || privileged rm -f "$tmp_file"
  }
  trap cleanup_install EXIT HUP INT TERM

  reject_destination_symlink
  if privileged test -e "$CODEX_SYSTEM_CONFIG"; then
    current_file=$(mktemp)
    privileged cat "$CODEX_SYSTEM_CONFIG" >"$current_file"
    if cmp -s "$current_file" "$CODEX_SHARED_CONFIG"; then
      rm -f "$current_file"
      current_file=''
      printf '%s\n' "既に最新です: $CODEX_SYSTEM_CONFIG"
      trap - EXIT HUP INT TERM
      return
    fi
    rm -f "$current_file"
    current_file=''
    printf '既存の %s を上記内容で更新しますか? [y/N] ' "$CODEX_SYSTEM_CONFIG"
    read -r answer
    case "$answer" in y | Y) ;; *) printf '%s\n' '更新を中止しました。'; return 1 ;; esac
  fi

  privileged install -d -m 0755 "$destination_dir"
  reject_destination_symlink
  tmp_file=$(privileged mktemp "$destination_dir/.config.toml.install.XXXXXX")
  privileged install -m 0644 "$CODEX_SHARED_CONFIG" "$tmp_file"
  if privileged test -L "$tmp_file" || ! privileged test -f "$tmp_file"; then
    printf '%s\n' "一時ファイルが通常ファイルではありません: $tmp_file" >&2
    exit 1
  fi
  reject_destination_symlink
  privileged mv -fh "$tmp_file" "$CODEX_SYSTEM_CONFIG"
  tmp_file=''
  trap - EXIT HUP INT TERM
  printf '%s\n' "導入しました: $CODEX_SYSTEM_CONFIG"
}

check_config() {
  local tmp_dir report
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM
  cp "$CODEX_SHARED_CONFIG" "$tmp_dir/config.toml"
  report="$tmp_dir/doctor.json"
  CODEX_HOME="$tmp_dir" codex doctor --json >"$report" || true
  jq -e '
    .checks["config.load"].status == "ok" and
    (.checks["config.load"].details["feature flag overrides"] | contains("runtime_metrics=true")) and
    .checks["sandbox.helpers"].details["approval policy"] == "OnRequest" and
    .checks["sandbox.helpers"].details["filesystem sandbox"] == "unrestricted"
  ' "$report" >/dev/null
  rm -rf "$tmp_dir"
  trap - EXIT HUP INT TERM
  printf '%s\n' '共有Codex設定の読み込みと代表値を確認しました。'
}

verify_config() {
  local tmp_dir
  if privileged test -L "$CODEX_SYSTEM_CONFIG" || ! privileged test -f "$CODEX_SYSTEM_CONFIG"; then
    printf '%s\n' "system config が通常ファイルとして導入されていません: $CODEX_SYSTEM_CONFIG" >&2
    exit 1
  fi
  if ! privileged cmp -s "$CODEX_SHARED_CONFIG" "$CODEX_SYSTEM_CONFIG"; then
    printf '%s\n' "system config が共有設定の正本と一致しません: $CODEX_SYSTEM_CONFIG" >&2
    exit 1
  fi
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM
  mkdir "$tmp_dir/expected-home" "$tmp_dir/actual-home"
  cp "$CODEX_SHARED_CONFIG" "$tmp_dir/expected-home/config.toml"
  CODEX_HOME="$tmp_dir/expected-home" codex doctor --json >"$tmp_dir/expected.json" || true
  CODEX_HOME="$tmp_dir/actual-home" codex doctor --json >"$tmp_dir/actual.json" || true
  jq -e --slurpfile expected "$tmp_dir/expected.json" '
    .checks["config.load"].status == "ok" and
    .checks["config.load"].details.model == $expected[0].checks["config.load"].details.model and
    .checks["config.load"].details["feature flag overrides"] == $expected[0].checks["config.load"].details["feature flag overrides"] and
    .checks["sandbox.helpers"].details["approval policy"] == $expected[0].checks["sandbox.helpers"].details["approval policy"] and
    .checks["sandbox.helpers"].details["filesystem sandbox"] == $expected[0].checks["sandbox.helpers"].details["filesystem sandbox"]
  ' "$tmp_dir/actual.json" >/dev/null
  rm -rf "$tmp_dir"
  trap - EXIT HUP INT TERM
  printf '%s\n' '有効なCodex設定の代表値を確認しました。'
}

case "${1-}" in
  dry-run) dry_run ;;
  install) install_config ;;
  check) check_config ;;
  verify) verify_config ;;
  *) printf 'Usage: %s {dry-run|install|check|verify}\n' "$0" >&2; exit 2 ;;
esac
