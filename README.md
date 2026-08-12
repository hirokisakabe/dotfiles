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

共有設定の `sandbox_mode = "danger-full-access"` は、個人専用macOSでの利用を前提とする既存値である。共有端末へ導入する場合は、この値を `workspace-write` へ変更する。

新規セットアップまたは共有設定の更新時は、先に適用内容を確認してから導入・検証する。

```sh
make codex-system-config-dry-run
make codex-system-config-install
make codex-system-config-verify
```

既存の管理外 `/etc/codex/config.toml` が異なる場合、installターゲットは差分を表示して確認を求め、同意なしには上書きしない。同じ内容が導入済みなら何も変更しない。system configのsymlinkはリンク先を意図せず読み書きしないよう、正常・リンク切れを問わず自動処理しない。`make codex-system-config-check` は実マシンのsystem/user configを変更せず、共有設定を一時的なuser layerとして読み込み、現在のsystem layerと組み合わせたときの構文と代表値を検査する。Codexにはsystem layerを無効化する診断オプションがないため、完全な単体検査ではない。

旧構成から更新する場合、`~/.codex/config.toml` が通常ファイルなら移行は不要である。symlinkの場合は `make stow-link` の前に `readlink` の出力を確認し、このdotfilesの `packages/codex/.codex/config.toml` を指していることを人が確認してから、一度だけ内容を保持した通常ファイルへ置き換える。

```sh
readlink "$HOME/.codex/config.toml"
tmp_file=$(mktemp "$HOME/.codex/config.toml.migrate.XXXXXX")
cp -pL "$HOME/.codex/config.toml" "$tmp_file"
mv "$tmp_file" "$HOME/.codex/config.toml"
test -f "$HOME/.codex/config.toml" && test ! -L "$HOME/.codex/config.toml"
```

symlinkがすでにリンク切れの場合は、dotfilesリポジトリのルートで `git log --all -- packages/codex/.codex/config.toml` を確認し、削除前のcommitから一時ファイルへ復元して置き換える。

```sh
tmp_file=$(mktemp "$HOME/.codex/config.toml.migrate.XXXXXX")
git show <削除前のcommit>:packages/codex/.codex/config.toml >"$tmp_file"
mv "$tmp_file" "$HOME/.codex/config.toml"
test -f "$HOME/.codex/config.toml" && test ! -L "$HOME/.codex/config.toml"
```

通常ファイル化を確認してから `make stow-link` を実行する。user config内の共有キーは必要に応じて削除し、project trust、hook承認、marketplace、Desktop / MCPのパスなどmachine-localな設定・状態だけを残す。

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
