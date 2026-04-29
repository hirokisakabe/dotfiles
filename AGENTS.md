# Repository Guidelines

This file is the single source of truth for AI coding agents (Claude Code, Codex CLI 等) working in this repository. `CLAUDE.md` is a symlink to this file.

## Overview

macOS 向けの dotfiles リポジトリ。Homebrew でパッケージ管理、GNU Stow でシンボリックリンク管理を行う。

## Project Structure & Module Organization

- `packages/`: one directory per tool (`zsh`, `vim`, `wezterm`, `git`, `codex`, etc.).
- `packages/*/`: mirrored home-directory layout (for example, `packages/yazi/.config/yazi/`).
- `packages/codex/`: contains `AGENTS.md`, Codex CLI の指示ファイル。
- `Makefile`: primary task entrypoint for setup, linking, and package maintenance.
- `install.sh`: bootstrap script used by `make install`.
- `Brewfile` / `Brewfile.lock.json`: Homebrew package definitions and lock data.

```
packages/           # Stow パッケージ（各ツールの設定ファイル）
├── zsh/           # .zshrc
├── vim/           # .vimrc
├── wezterm/       # .wezterm.lua
├── git/           # .gitconfig, .gitignore_global
├── npm/           # .default-npm-packages
├── starship/      # .config/starship.toml
├── yazi/          # .config/yazi/yazi.toml
├── claude/        # .claude/settings.json, .claude/CLAUDE.md
├── issuekit/      # APM / Claude Code plugin として配布する issue-driven skills
└── codex/         # .codex/AGENTS.md (Codex CLI の指示ファイル)
```

### Stow の仕組み

`packages/` 配下の各ディレクトリは、ホームディレクトリ（`~`）へのシンボリックリンクとして展開される。例えば `packages/zsh/.zshrc` は `~/.zshrc` にリンクされる。

新しいツールの設定を追加する場合：

1. `packages/<tool>/` ディレクトリを作成
2. ホームディレクトリからの相対パスで設定ファイルを配置
3. `Makefile` の `PACKAGES` 変数にツール名を追加

## Build, Test, and Development Commands

Use `make` targets as the standard workflow:

- `make help`: 利用可能なタスク一覧を表示。
- `make install`: 初回セットアップ（Homebrew インストール、パッケージインストール、シンボリックリンク作成）を `install.sh` 経由で実行。
- `make update`: `Brewfile` から Homebrew パッケージを更新。
- `make sync`: 現在の Homebrew 状態を `Brewfile` に書き戻す。
- `make link`: `packages/` 配下を `$HOME` に stow でシンボリックリンク化。
- `make unlink`: stow 管理のシンボリックリンクを削除。
- `make setup-mcp`: Claude Code の MCP サーバーをセットアップ。

Example: `make link` after adding a new file under `packages/zsh/`.

## Coding Style & Naming Conventions

- Keep directory names tool-oriented and lowercase (for example, `packages/starship`).
- Preserve target paths exactly as they should appear in `$HOME` (for example, `.config/gh-dash/config.yml`).
- Prefer minimal, focused changes per package.
- For shell snippets, use POSIX-compatible style unless the target tool requires `zsh`-specific syntax.

Prettier is configured as the formatter. Run `npx prettier@3 --check .` to verify formatting (フォーマット適用は `npx prettier@3 --write .`)。See `.prettierignore` for excluded files.

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
