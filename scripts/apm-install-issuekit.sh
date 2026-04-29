#!/bin/bash

# Deploy issuekit skill bundle to ~/.claude/skills/ via APM.
#
# Idempotent and non-destructive: respects an existing ~/apm.yml, only adding
# the issuekit dependency when missing. Run from `make install` and `make link`.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ISSUEKIT_DIR="$DOTFILES_DIR/packages/claude-skills"
APM_YML="$HOME/apm.yml"

if ! command -v apm >/dev/null 2>&1; then
  echo "apm CLI not found on PATH; skipping issuekit deploy." >&2
  echo "Install with: brew install microsoft/apm/apm" >&2
  exit 0
fi

cd "$HOME"

if [ ! -f "$APM_YML" ] || ! grep -qF "$ISSUEKIT_DIR" "$APM_YML"; then
  apm install "$ISSUEKIT_DIR"
else
  apm install
fi
