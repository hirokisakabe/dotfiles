# dotfiles

## 主なツール

| 役割       | ツール                     |
| ---------- | -------------------------- |
| ターミナル | WezTerm＋zsh               |
| エディタ   | VS Code                    |
| AIとの実装 | Claude Code／Codex         |
| 環境管理   | Homebrew＋mise             |
| macOS操作  | Raycast、Rectangle、AltTab |

## セットアップ

```sh
make install
```

他のタスクは `make help` を参照。

VS Code の既存設定がある場合は、`make install` / `make stow-link` の前に
[VS Code 設定の移行手順](docs/vscode.md)を実施する。
