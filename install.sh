#!/bin/bash

set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  printf '%s\n' "Unsupported OS. This setup supports macOS only." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  printf '\n-- install Homebrew --\n'
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash
fi

if command -v brew >/dev/null 2>&1; then
  brew_command="$(command -v brew)"
elif [ -x /opt/homebrew/bin/brew ]; then
  brew_command="/opt/homebrew/bin/brew"
elif [ -x /usr/local/bin/brew ]; then
  brew_command="/usr/local/bin/brew"
else
  printf '%s\n' "Homebrew was installed but the brew command could not be found." >&2
  exit 1
fi

eval "$("$brew_command" shellenv)"

printf '\n-- install dotfiles environment --\n'
make _install

printf '\n-- done! --\n'
