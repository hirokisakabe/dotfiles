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

`AGENT_SKILLS` には `owner/repo:skill-name` に加えて、`owner/repo:path/to/skill` 形式でリポジトリ内のnested skillも指定できる。

### iTerm2

`make stow-link` と `make iterm2-configure` の実行後、iTerm2を起動（起動中なら終了して再起動）すると、`~/.config/iterm2/com.googlecode.iterm2.plist` の設定を読み込む。`make install` では両方を実行する。

WezTermと同じAtrium Library配色、OverpassM Nerd Font / Moralerspace Argonの13pt、文字間隔・行間隔、120列×40行、10,000行のスクロールバックを設定している。余白は左右16pt・上下13pt、タブはMinimalテーマで近似する。`Cmd+|` / `Cmd+\` で左右 / 上下に分割し、`Shift+Enter` はWezTermと同じESC+CRを送る。`Cmd+W` はiTerm2標準のペインを閉じる操作、`Cmd+Q` はアプリ終了のままとする。

設定の正本は `packages/iterm2/` 配下。iTerm2の設定画面からの変更は正本へ自動保存しないため、継続する変更はplistを編集する。

タブバーは1タブでもフルスクリーンでも常時表示し、閉じるボタンを表示する。フルスクリーン時は自動的に隠れるタイトルバー内にタブを配置せず、独立したバーとして表示する（Advancedの `Place tabs in the window's titlebar in full screen mode` を無効化）。タブをドラッグすると別ウィンドウへ切り離し・移動できる。

## 主要コマンド

| Command                            | 用途                                                                 |
| ---------------------------------- | -------------------------------------------------------------------- |
| `make help`                        | 利用可能なタスク一覧を表示                                           |
| `make install`                     | dotfiles環境を一括セットアップ                                       |
| `make update`                      | インストール済みHomebrewパッケージと管理対象の外部リソースを一括更新 |
| `make doctor`                      | dotfilesの設定状態を読み取り専用で検査                               |
| `make brew-install`                | `Brewfile` のパッケージをインストール                                |
| `make brew-update`                 | インストール済みHomebrewパッケージを全更新し `Brewfile` を適用       |
| `make brewfile-dump`               | 現在のHomebrew状態を `Brewfile` に書き出し                           |
| `make brew-prune`                  | `Brewfile` にないHomebrewパッケージを確認後に削除                    |
| `make stow-link`                   | `packages/` 配下を `$HOME` にシンボリックリンク化                    |
| `make stow-unlink`                 | Stow管理のシンボリックリンクを削除                                   |
| `make mise-install`                | mise管理の開発CLIとTerraformをインストール                           |
| `make iterm2-configure`            | Stow管理のiTerm2設定を次回起動から読み込む                           |
| `make skills-install`              | 管理対象のagent skillをインストール                                  |
| `make skills-update`               | インストール済みのagent skillを更新                                  |
| `make codex-system-config-dry-run` | Codex system configの適用内容・差分を表示                            |
| `make codex-system-config-install` | Codexの共有設定を `/etc/codex/config.toml` へ導入                    |
| `make codex-system-config-check`   | Codex共有設定を一時ディレクトリで非破壊検証                          |
| `make codex-system-config-verify`  | 導入後のCodex設定の代表値を診断                                      |

## 詳細

ディレクトリ構成、コーディング規約、AI コーディングエージェント向けの指示などは [`AGENTS.md`](./AGENTS.md) を参照。
