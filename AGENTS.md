# Repository Guidelines

## Project Structure & Module Organization

This repository manages dotfiles and CLI tool settings with GNU Stow.

- `packages/`: one directory per tool (`zsh`, `vim`, `wezterm`, `git`, `codex`, etc.).
- `packages/*/`: mirrored home-directory layout (for example, `packages/yazi/.config/yazi/`).
- `Makefile`: primary task entrypoint for setup, linking, and package maintenance.
- `install.sh`: bootstrap script used by `make install`.
- `Brewfile` / `Brewfile.lock.json`: Homebrew package definitions and lock data.

## Build, Test, and Development Commands

Use `make` targets as the standard workflow:

- `make help`: list available tasks.
- `make install`: run initial setup via `install.sh`.
- `make update`: install/update Homebrew dependencies from `Brewfile`.
- `make sync`: dump current Homebrew state back to `Brewfile`.
- `make link`: create symlinks from `packages/` into `$HOME` with stow.
- `make unlink`: remove stow-managed symlinks.

Example: `make link` after adding a new file under `packages/zsh/`.

## Coding Style & Naming Conventions

- Keep directory names tool-oriented and lowercase (for example, `packages/starship`).
- Preserve target paths exactly as they should appear in `$HOME` (for example, `.config/gh-dash/config.yml`).
- Prefer minimal, focused changes per package.
- For shell snippets, use POSIX-compatible style unless the target tool requires `zsh`-specific syntax.

Prettier is configured as the formatter. Run `npx prettier@3 --check .` to verify formatting. See `.prettierignore` for excluded files.

## Testing Guidelines

There is no centralized automated test suite in this repository.

- Verify symlink behavior with `make link` and `make unlink`.
- Run `make help` to confirm Makefile integrity after edits.
- For tool-specific configs, run the tool’s own check command when available (for example, `git config --list`).

## Commit & Pull Request Guidelines

- Follow Conventional Commit-like prefixes seen in history: `feat:`, `fix:`, `chore:`.
- Keep commit scope small and message specific (example: `fix: adjust yazi preview keymap`).
- Open PRs with:
  - purpose and impacted package paths,
  - local verification steps (`make link`, `make help`, etc.),
  - screenshots/log snippets only when UI behavior changes.
