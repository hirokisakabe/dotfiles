# dotfiles

macOS 向けの dotfiles リポジトリ。Homebrew でパッケージ管理、[GNU Stow](https://www.gnu.org/software/stow/) でシンボリックリンク管理を行う。

## 前提

- macOS
- Xcode Command Line Tools

## セットアップ

```sh
make install
```

`install.sh` でHomebrewをbootstrapした後、Makefileの個別ターゲットを順番に実行する。Homebrewパッケージ、シンボリックリンク、mise管理ツール、agent skill、GitHub CLI拡張、GitAlias、Vimプラグイン、batテーマキャッシュをセットアップし、最後に `make doctor` で状態を検査する。

MCP設定は各ツール自身の設定ファイルを更新するため、Stow管理との衝突を避けて一括セットアップから分離している。必要な場合は `make mcp-setup` を明示的に実行する。

### Codex設定

複数マシンで共有するCodex設定は [`config/codex/config.toml`](./config/codex/config.toml) を正本とし、`/etc/codex/config.toml` へ導入する。新規セットアップまたは共有設定の更新時は、適用内容を確認してから導入・検証する。

```sh
make codex-system-config-dry-run
make codex-system-config-install
make codex-system-config-verify
```

設定レイヤーの役割、安全設計、検証上の制約、Stow管理との境界は [`docs/codex.md`](./docs/codex.md) を参照。

### Agent skill

`make skills-install` は管理対象のagent skillを単一の正本として `~/.agents/skills/<name>` にインストールする。Codexはこの共通ディレクトリから直接読み込み、Claude Codeは `~/.claude/skills/<name>` から正本へのsymlinkを介して同じskillを利用する。これにより、両方のskill selectorに同名skillが重複して表示されない。

`make skills-update` は `~/.agents/skills` を明示して、共通配置されたskillを更新する。

## 主要コマンド

| Command                            | 用途                                              |
| ---------------------------------- | ------------------------------------------------- |
| `make help`                        | 利用可能なタスク一覧を表示                        |
| `make install`                     | dotfiles環境を一括セットアップ                    |
| `make update`                      | 管理対象のパッケージと外部リソースを一括更新      |
| `make doctor`                      | dotfilesの設定状態を読み取り専用で検査            |
| `make brew-install`                | `Brewfile` のパッケージをインストール             |
| `make brew-update`                 | Homebrewと `Brewfile` のパッケージを更新          |
| `make brewfile-dump`               | 現在のHomebrew状態を `Brewfile` に書き出し        |
| `make brew-prune`                  | `Brewfile` にないHomebrewパッケージを確認後に削除 |
| `make stow-link`                   | `packages/` 配下を `$HOME` にシンボリックリンク化 |
| `make stow-unlink`                 | Stow管理のシンボリックリンクを削除                |
| `make mise-install`                | mise管理の開発CLIとTerraformをインストール        |
| `make skills-install`              | 管理対象のagent skillをインストール               |
| `make skills-update`               | インストール済みのagent skillを更新               |
| `make codex-system-config-dry-run` | Codex system configの適用内容・差分を表示         |
| `make codex-system-config-install` | Codexの共有設定を `/etc/codex/config.toml` へ導入 |
| `make codex-system-config-check`   | Codex共有設定を一時ディレクトリで非破壊検証       |
| `make codex-system-config-verify`  | 導入後のCodex設定の代表値を診断                   |
| `make mcp-setup`                   | Claude CodeとCodexのMCPサーバーを設定             |

## 詳細

ディレクトリ構成、コーディング規約、AI コーディングエージェント向けの指示などは [`AGENTS.md`](./AGENTS.md) を参照。
