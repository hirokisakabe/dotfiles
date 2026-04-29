#!/bin/bash

# Deploy Claude Code skills/hooks to ~/.claude/ via APM.
#
# Idempotent and non-destructive: respects an existing ~/apm.yml, only adding
# missing dependencies. Run from `make install` and `make link`.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ISSUEKIT_DIR="$DOTFILES_DIR/packages/claude-skills"
APM_YML="$HOME/apm.yml"

DEPS=(
  "$ISSUEKIT_DIR"
  "max-sixty/worktrunk"
  "anthropics/skills/skills/frontend-design"
  "anthropics/skills/skills/skill-creator"
)

if ! command -v apm >/dev/null 2>&1; then
  echo "apm CLI not found on PATH; skipping APM deploy." >&2
  echo "Install with: brew install microsoft/apm/apm" >&2
  exit 0
fi

cd "$HOME"

missing=()
for dep in "${DEPS[@]}"; do
  if [ ! -f "$APM_YML" ] || ! grep -qF "$dep" "$APM_YML"; then
    missing+=("$dep")
  fi
done

if [ "${#missing[@]}" -gt 0 ]; then
  apm install "${missing[@]}"
else
  apm install
fi
