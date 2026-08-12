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

複数マシンで共有するCodexのデフォルト設定は [`config/codex/config.toml`](./config/codex/config.toml) を正本とし、`/etc/codex/config.toml` へ導入する。Codex自身が更新する `~/.codex/config.toml` はmachine-localな通常ファイルとしてGit / Stow管理から外す。Codexはuser configをsystem configより優先するため、user configに同じキーがある場合はmachine-localな値が有効になる。

新規セットアップまたは共有設定の更新時は、先に適用内容を確認してから導入・検証する。

```sh
make codex-system-config-dry-run
make codex-system-config-install
make codex-system-config-verify
```

既存の管理外 `/etc/codex/config.toml` が異なる場合、installターゲットは差分を表示して確認を求め、同意なしには上書きしない。同じ内容が導入済みなら何も変更しない。system configのsymlinkはリンク先を意図せず読み書きしないよう、正常・リンク切れを問わず自動処理しない。`make codex-system-config-check` は実マシンのsystem/user configを変更せず、一時的な `CODEX_HOME` で共有設定の構文と代表値を検査する。

旧構成からの移行では、`make stow-link` が先に `make codex-user-config-migrate` を実行する。`~/.codex/config.toml` がこのdotfilesの旧 `packages/codex/.codex/config.toml` を指すsymlinkの場合だけ、現在の内容（リンク先が削除済みならGit履歴上の最終内容）を保持した通常ファイルへ置き換える。既存の通常ファイルには触れず、管理外symlinkはエラーにして自動変更しない。移行後はuser config内の共有キーを必要に応じて削除し、project trust、hook承認、marketplace、Desktop / MCPのパスなどmachine-localな設定・状態だけを残す。

`packages/codex/.codex/` では引き続き `AGENTS.md` と `rules/default.rules` だけをStow管理する。project trust、hook状態、marketplaceキャッシュ、Codex Desktopが生成したMCP/runtimeの絶対パス、TUIのmachine-local状態は共有設定へ追加しない。

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
