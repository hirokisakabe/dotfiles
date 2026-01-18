# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS 向けの dotfiles リポジトリ。Homebrew でパッケージ管理、GNU Stow でシンボリックリンク管理を行う。

## Commands

```bash
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
├── tmux/          # .tmux.conf
├── wezterm/       # .wezterm.lua
├── git/           # .gitconfig, .gitignore_global
├── npm/           # .default-npm-packages
├── starship/      # .config/starship.toml
├── yazi/          # .config/yazi/yazi.toml
├── claude/        # .claude/settings.json, .claude/CLAUDE.md
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
