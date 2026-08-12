# Codex設定

## 設定レイヤー

複数マシンで共有するデフォルト設定は [`../config/codex/config.toml`](../config/codex/config.toml) を正本とし、system configの `/etc/codex/config.toml` へ導入する。

Codex自身が更新するuser configの `~/.codex/config.toml` は、machine-localな通常ファイルとしてGit / Stow管理から外す。Codexはuser configをsystem configより優先するため、両方に同じキーがある場合はmachine-localな値が有効になる。

## 導入と検証

新規セットアップまたは共有設定の更新時は、dry-runで適用内容を確認してから導入・検証する。

```sh
make codex-system-config-dry-run
make codex-system-config-install
make codex-system-config-verify
```

共有設定自体の構文と代表値は、実マシンのsystem/user configを変更せずに検査できる。

```sh
make codex-system-config-check
```

## system config導入時の安全設計

- dry-runは、導入先が未作成なら新規作成する内容を、既存ファイルなら正本との差分を表示する。
- installはdry-runを先に実行する。既存の管理外ファイルと正本が異なる場合は確認を求め、同意なしには上書きしない。
- 正本と同じ内容が導入済みなら、installはファイルを変更しない。
- system configがsymlinkの場合は、正常・リンク切れを問わずdry-runとinstallを停止する。リンク先を意図せず読み書きしないため、symlinkは自動処理しない。
- installは一時ファイルを通常ファイルとして作成してから導入先へ移動し、不完全な内容が残ることを避ける。
- verifyは導入先が通常ファイルであり、正本と一致することを確認してから有効な代表値を検査する。

## `danger-full-access` の注意

共有設定の `sandbox_mode = "danger-full-access"` は、個人専用macOSでの利用を前提とする。この設定ではCodexのfilesystem sandboxによる制限がないため、共有端末へそのまま導入しない。共有端末で利用する場合は、正本の値を `workspace-write` など用途に合う制限付きモードへ変更してから導入する。

## `codex-system-config-check` の制約

`make codex-system-config-check` は共有設定を一時的なuser layerとして読み込み、現在のsystem layerと組み合わせた状態で構文と代表値を検査する。実マシンの設定ファイルは変更しない。

Codexにはsystem layerを無効化する診断オプションがないため、この検査は共有設定だけの完全な単体検査ではない。実際に導入したsystem configの確認には `make codex-system-config-verify` を使用する。

## Stow管理との境界

`packages/codex/.codex/` では `AGENTS.md` と `rules/default.rules` だけをStow管理する。`~/.codex/config.toml` と、次のようなmachine-localな設定・状態は共有設定へ追加しない。

- project trust
- hook承認とhook状態
- marketplaceキャッシュ
- Codex Desktopが生成したMCP/runtimeの絶対パス
- TUIのmachine-local状態
