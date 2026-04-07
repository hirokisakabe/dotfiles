#!/usr/bin/env bash
# 履歴ファイル ~/.claude/webfetch-history.jsonl のドメインを
# packages/claude/.claude/settings.json の permissions.allow に追記する

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HISTORY_FILE="$HOME/.claude/webfetch-history.jsonl"
SETTINGS_FILE="$REPO_ROOT/packages/claude/.claude/settings.json"

if [ ! -f "$HISTORY_FILE" ]; then
  echo "履歴ファイルが見つかりません: $HISTORY_FILE"
  exit 0
fi

domains=$(jq -r '.domain' "$HISTORY_FILE" | sort -u)

if [ -z "$domains" ]; then
  echo "履歴にドメインがありません"
  exit 0
fi

new_count=0
for domain in $domains; do
  perm="WebFetch(domain:$domain)"
  if jq -e --arg p "$perm" '.permissions.allow | any(. == $p)' "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo "既存: $perm"
    continue
  fi
  echo "追加: $perm"
  tmp=$(mktemp)
  jq --arg p "$perm" '.permissions.allow += [$p]' "$SETTINGS_FILE" >"$tmp"
  mv "$tmp" "$SETTINGS_FILE"
  new_count=$((new_count + 1))
done

echo ""
echo "${new_count} 件のドメインを追加しました。"
echo "変更内容を確認してください: git diff packages/claude/.claude/settings.json"
