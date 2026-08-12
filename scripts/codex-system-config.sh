#!/usr/bin/env bash

set -euo pipefail

: "${CODEX_SHARED_CONFIG:?CODEX_SHARED_CONFIG is required}"
: "${CODEX_SYSTEM_CONFIG:?CODEX_SYSTEM_CONFIG is required}"

CODEX_CONFIG_SUDO=${CODEX_CONFIG_SUDO-sudo}

cleanup_local_path=''
cleanup_privileged_path=''

privileged() {
  if [ -n "$CODEX_CONFIG_SUDO" ]; then
    # Preserve Makefile's support for a command plus fixed arguments.
    # shellcheck disable=SC2086
    $CODEX_CONFIG_SUDO "$@"
  else
    "$@"
  fi
}

cleanup_on_exit() {
  local status=$?
  trap - EXIT
  set +e
  [ -z "$cleanup_local_path" ] || rm -rf "$cleanup_local_path"
  [ -z "$cleanup_privileged_path" ] || privileged rm -f "$cleanup_privileged_path"
  exit "$status"
}

exit_on_signal() {
  local status=$1
  exit "$status"
}

trap cleanup_on_exit EXIT
trap 'exit_on_signal 129' HUP
trap 'exit_on_signal 130' INT
trap 'exit_on_signal 143' TERM

reject_destination_symlink() {
  if privileged test -L "$CODEX_SYSTEM_CONFIG"; then
    printf '%s\n' "symlink は自動処理しません: $CODEX_SYSTEM_CONFIG" >&2
    exit 1
  fi
}

dry_run() {
  umask 077
  reject_destination_symlink
  if privileged test -e "$CODEX_SYSTEM_CONFIG"; then
    cleanup_local_path=$(mktemp)
    privileged cat "$CODEX_SYSTEM_CONFIG" >"$cleanup_local_path"
    if cmp -s "$cleanup_local_path" "$CODEX_SHARED_CONFIG"; then
      printf '%s\n' "変更はありません: $CODEX_SYSTEM_CONFIG"
    else
      printf '%s\n' "適用予定の差分: $CODEX_SYSTEM_CONFIG"
      diff -u "$cleanup_local_path" "$CODEX_SHARED_CONFIG" || true
    fi
    rm -f "$cleanup_local_path"
    cleanup_local_path=''
  else
    printf '%s\n' "新規作成予定: $CODEX_SYSTEM_CONFIG"
    sed -n '1,$p' "$CODEX_SHARED_CONFIG"
  fi
}

install_config() {
  local destination_dir answer
  umask 077
  destination_dir=$(dirname "$CODEX_SYSTEM_CONFIG")

  reject_destination_symlink
  if privileged test -e "$CODEX_SYSTEM_CONFIG"; then
    cleanup_local_path=$(mktemp)
    privileged cat "$CODEX_SYSTEM_CONFIG" >"$cleanup_local_path"
    if cmp -s "$cleanup_local_path" "$CODEX_SHARED_CONFIG"; then
      rm -f "$cleanup_local_path"
      cleanup_local_path=''
      printf '%s\n' "既に最新です: $CODEX_SYSTEM_CONFIG"
      return
    fi
    rm -f "$cleanup_local_path"
    cleanup_local_path=''
    printf '既存の %s を上記内容で更新しますか? [y/N] ' "$CODEX_SYSTEM_CONFIG"
    read -r answer
    case "$answer" in y | Y) ;; *) printf '%s\n' '更新を中止しました。'; return 1 ;; esac
  fi

  privileged install -d -m 0755 "$destination_dir"
  reject_destination_symlink
  cleanup_privileged_path=$(privileged mktemp "$destination_dir/.config.toml.install.XXXXXX")
  privileged install -m 0644 "$CODEX_SHARED_CONFIG" "$cleanup_privileged_path"
  if privileged test -L "$cleanup_privileged_path" || ! privileged test -f "$cleanup_privileged_path"; then
    printf '%s\n' "一時ファイルが通常ファイルではありません: $cleanup_privileged_path" >&2
    exit 1
  fi
  reject_destination_symlink
  privileged mv -fh "$cleanup_privileged_path" "$CODEX_SYSTEM_CONFIG"
  cleanup_privileged_path=''
  printf '%s\n' "導入しました: $CODEX_SYSTEM_CONFIG"
}

check_config() {
  local report
  cleanup_local_path=$(mktemp -d)
  cp "$CODEX_SHARED_CONFIG" "$cleanup_local_path/config.toml"
  report="$cleanup_local_path/doctor.json"
  CODEX_HOME="$cleanup_local_path" codex doctor --json >"$report" || true
  jq -e '
    .checks["config.load"].status == "ok" and
    (.checks["config.load"].details["feature flag overrides"] | contains("runtime_metrics=true")) and
    .checks["sandbox.helpers"].details["approval policy"] == "OnRequest" and
    .checks["sandbox.helpers"].details["filesystem sandbox"] == "unrestricted"
  ' "$report" >/dev/null
  rm -rf "$cleanup_local_path"
  cleanup_local_path=''
  printf '%s\n' '共有Codex設定の読み込みと代表値を確認しました。'
}

verify_config() {
  if privileged test -L "$CODEX_SYSTEM_CONFIG" || ! privileged test -f "$CODEX_SYSTEM_CONFIG"; then
    printf '%s\n' "system config が通常ファイルとして導入されていません: $CODEX_SYSTEM_CONFIG" >&2
    exit 1
  fi
  if ! privileged cmp -s "$CODEX_SHARED_CONFIG" "$CODEX_SYSTEM_CONFIG"; then
    printf '%s\n' "system config が共有設定の正本と一致しません: $CODEX_SYSTEM_CONFIG" >&2
    exit 1
  fi
  cleanup_local_path=$(mktemp -d)
  mkdir "$cleanup_local_path/expected-home" "$cleanup_local_path/actual-home"
  cp "$CODEX_SHARED_CONFIG" "$cleanup_local_path/expected-home/config.toml"
  CODEX_HOME="$cleanup_local_path/expected-home" codex doctor --json >"$cleanup_local_path/expected.json" || true
  CODEX_HOME="$cleanup_local_path/actual-home" codex doctor --json >"$cleanup_local_path/actual.json" || true
  jq -e --slurpfile expected "$cleanup_local_path/expected.json" '
    .checks["config.load"].status == "ok" and
    .checks["config.load"].details.model == $expected[0].checks["config.load"].details.model and
    .checks["config.load"].details["feature flag overrides"] == $expected[0].checks["config.load"].details["feature flag overrides"] and
    .checks["sandbox.helpers"].details["approval policy"] == $expected[0].checks["sandbox.helpers"].details["approval policy"] and
    .checks["sandbox.helpers"].details["filesystem sandbox"] == $expected[0].checks["sandbox.helpers"].details["filesystem sandbox"]
  ' "$cleanup_local_path/actual.json" >/dev/null
  rm -rf "$cleanup_local_path"
  cleanup_local_path=''
  printf '%s\n' '有効なCodex設定の代表値を確認しました。'
}

case "${1-}" in
  dry-run) dry_run ;;
  install) install_config ;;
  check) check_config ;;
  verify) verify_config ;;
  *) printf 'Usage: %s {dry-run|install|check|verify}\n' "$0" >&2; exit 2 ;;
esac
