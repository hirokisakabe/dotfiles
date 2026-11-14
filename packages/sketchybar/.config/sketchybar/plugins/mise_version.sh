#!/usr/bin/env bash
# mise 管理ツールの現在バージョンと最新バージョンを取得し、
# SketchyBar アイテム "$NAME" に反映する。
#
# 使い方: mise_version.sh <tool>
#   例: mise_version.sh node

set -uo pipefail

TOOL="${1:?tool name required}"

# launchd 経由で起動されると PATH が最小なので明示的に補う。
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

if ! command -v mise >/dev/null 2>&1; then
    sketchybar --set "$NAME" label="$TOOL: mise not found" label.color=0xfff38ba8
    exit 0
fi

current="$(mise current "$TOOL" 2>/dev/null | head -n1 || true)"
# mise latest はネットワークを叩く。オフライン時は空文字が入り "latest 未取得" 表示になる。
latest="$(mise latest "$TOOL" 2>/dev/null | head -n1 || true)"

# Catppuccin Mocha 準拠
COLOR_TEXT=0xffcdd6f4    # 通常
COLOR_MUTED=0xff6c7086   # 未取得
COLOR_OK=0xffa6e3a1      # 最新一致
COLOR_WARN=0xfff9e2af    # 更新あり

if [[ -z "$current" ]]; then
    label="$TOOL --"
    color="$COLOR_MUTED"
elif [[ -z "$latest" ]]; then
    label="$TOOL $current"
    color="$COLOR_TEXT"
elif [[ "$current" == "$latest" ]]; then
    label="$TOOL $current"
    color="$COLOR_OK"
else
    label="$TOOL $current → $latest"
    color="$COLOR_WARN"
fi

sketchybar --set "$NAME" label="$label" label.color="$color"
