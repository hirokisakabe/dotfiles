# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS 向けの dotfiles リポジトリ。Homebrew でパッケージ管理、GNU Stow でシンボリックリンク管理を行う。

## Commands

```bash
# 利用可能なコマンド一覧を表示
make help

# 初回セットアップ（Homebrew インストール、パッケージインストール、シンボリックリンク作成）
make install

# Brewfile からパッケージを更新
make update

# 現在のインストール済みパッケージを Brewfile に同期
make sync

# シンボリックリンクを作成
make link

# シンボリックリンクを削除
make unlink

# Claude Code の MCP サーバーをセットアップ
make setup-mcp
```

## Architecture

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
├── claude-skills/ # .claude/skills/ (Claude Code カスタムスキル)
└── codex/         # .codex/AGENTS.md

Brewfile           # Homebrew パッケージ定義
install.sh         # 初回セットアップスクリプト
Makefile           # タスクランナー
```

### Stow の仕組み

`packages/` 配下の各ディレクトリは、ホームディレクトリ（`~`）へのシンボリックリンクとして展開される。例えば `packages/zsh/.zshrc` は `~/.zshrc` にリンクされる。

新しいツールの設定を追加する場合：
1. `packages/<tool>/` ディレクトリを作成
2. ホームディレクトリからの相対パスで設定ファイルを配置
3. `Makefile` の `PACKAGES` 変数にツール名を追加

## Claude Code Workflow

main ブランチ上の Claude Code セッションは、議論・設計・レビュー専用として扱う。
実装に移るときは、同じ WezTerm タブの右ペインに実装セッションを起動する。

```bash
# 議論セッション（main）から実装セッションを右ペインで開始
cwtstart <タスクの説明>
```

- `cwtstart` は右ペインがあればそこへ、なければ右ペインを作成して `cwt <タスク>` を実行する。
- 左側（main）の議論セッションは維持したまま、右側ペインで実装を進める。
