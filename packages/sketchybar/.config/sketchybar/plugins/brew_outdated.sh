#!/usr/bin/env bash
# brew outdated のパッケージ数を SketchyBar アイテム "$NAME" に反映する。
#
# ローカルの formula メタデータのみを参照するためネットワークは叩かない。
# 最新のメタデータが欲しい場合は別途 `brew update` を走らせること
# (例: `make brew-update` や `make update`)。

set -uo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# launchd 配下では HOMEBREW_* 変数が未設定なので brew outdated が空を返す。
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

COLOR_TEXT=0xffcdd6f4
COLOR_MUTED=0xff6c7086
COLOR_OK=0xffa6e3a1
COLOR_WARN=0xfff9e2af
COLOR_ALERT=0xfff38ba8

if ! command -v brew >/dev/null 2>&1; then
    sketchybar --set "$NAME" label="brew --" label.color="$COLOR_MUTED"
    exit 0
fi

# `--formula` に限定しないと、launchd 配下では cask のバージョン判定で
# brew 内部の plutil 呼び出しが失敗し、全体が空を返してしまう。
count="$(brew outdated --formula --quiet 2>/dev/null | wc -l | tr -d ' ')"

if [[ -z "$count" ]]; then
    label="brew --"
    color="$COLOR_MUTED"
elif [[ "$count" == "0" ]]; then
    label="brew ok"
    color="$COLOR_OK"
elif (( count >= 10 )); then
    label="brew $count"
    color="$COLOR_ALERT"
else
    label="brew $count"
    color="$COLOR_WARN"
fi

sketchybar --set "$NAME" label="$label" label.color="$color"
