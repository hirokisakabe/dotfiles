#!/usr/bin/env bash
# PostToolUse hook: successful WebFetch のドメインを ~/.claude/webfetch-history.jsonl に追記する

set -euo pipefail

input=$(cat)

# matcher で WebFetch にフィルタ済みだが念のため確認
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
[ "$tool_name" = "WebFetch" ] || exit 0

# エラー時はスキップ
is_error=$(printf '%s' "$input" | jq -r '.tool_response.is_error // false')
[ "$is_error" = "false" ] || exit 0

# URL からドメインを抽出
url=$(printf '%s' "$input" | jq -r '.tool_input.url // empty')
[ -n "$url" ] || exit 0

domain=$(printf '%s' "$url" | sed -E 's|https?://||' | cut -d'/' -f1)
[ -n "$domain" ] || exit 0

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cwd=$(pwd)

printf '{"ts":"%s","domain":"%s","cwd":"%s"}\n' "$ts" "$domain" "$cwd" \
  >>"$HOME/.claude/webfetch-history.jsonl"
