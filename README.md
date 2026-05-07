# dotfiles

macOS 向けの dotfiles リポジトリ。Homebrew でパッケージ管理、[GNU Stow](https://www.gnu.org/software/stow/) でシンボリックリンク管理を行う。

## 前提

- macOS
- [Homebrew](https://brew.sh/)
- GNU Stow（`make install` で導入される）

## セットアップ

```sh
make install
```

`install.sh` 経由で Homebrew のインストール、`Brewfile` のパッケージ導入、`packages/` 配下のシンボリックリンク作成までを行う。

## 主要コマンド

| Command        | 用途                                                      |
| -------------- | --------------------------------------------------------- |
| `make help`    | 利用可能なタスク一覧を表示                                |
| `make install` | 初回セットアップ                                          |
| `make link`    | `packages/` 配下を `$HOME` に stow でシンボリックリンク化 |
| `make unlink`  | stow 管理のシンボリックリンクを削除                       |
| `make update`  | `Brewfile` から Homebrew パッケージを更新                 |
| `make sync`    | 現在の Homebrew 状態を `Brewfile` に書き戻し              |

## 詳細

ディレクトリ構成、コーディング規約、AI コーディングエージェント向けの指示などは [`AGENTS.md`](./AGENTS.md) を参照。
