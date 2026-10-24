# VS Code 設定の管理と移行

macOS の VS Code Stable の Default Profile にある
`~/Library/Application Support/Code/User/settings.json` だけを、
`packages/vscode/Library/Application Support/Code/User/settings.json` から GNU Stow でリンクする。
`make install` / `make stow-link` の対象なので、既存設定がある環境では先に以下の移行を行う。
この PR では実ホームの設定・リンク・Settings Sync を変更していない。

別プロファイルの `User/profiles/*/settings.json`、Insiders、ワークスペース設定、
keybindings、拡張機能一覧、キャッシュ、globalStorage は管理対象外。
User ディレクトリ全体はリンクしない。拡張機能は自動インストールしない。
既存設定の Prettier、Shell Format、Terraform、YAML、GitHub Copilot、Claude Code、
vscode-icons、Vibrancy、md-pptx 等の機能には対応する拡張機能が別途必要で、
フォント `OverpassM Nerd Font` や WezTerm も別途用意する。
既存の AI 指示、編集・UI・YAML 設定は未使用に見えるものも保持する。

## 公開設定から除外した項目

- `@azure.argTenant`: Azure テナントの識別子。接続先は各環境で選び直す。
- `azureTerraform.survey`: アンケートの日時・無視回数という生成状態。通知が再表示される可能性がある。
- `md-pptx.defaultOutputDirectory`: 個人の絶対出力パス。変数展開の対応を確認していないため置換せず除外した。出力時に保存先を指定する。
- `dotfiles.repository`: この PR の対象とは異なる個人のリポジトリ識別子。これを使う環境ではローカルで接続先を指定する。

これらの値はバックアップに残る。VS Code のユーザー設定に戻すとリンク先の公開ファイルにも入るため、
そのままコミットしない。必要なら用途に適したローカル設定を使うか、リンクを外して個別管理する。

## 初回移行

1. VS Code で `Settings Sync: Configure...` を開き、**Settings カテゴリを OFF** にする。
   Sync が未使用なら OFF のままにする。他カテゴリの変更は不要。
   リンク中は Settings の同期を再度有効にしない。
2. Profiles メニューで **Default Profile** を選び、対象が通常の User/settings.json であることを確認する。
   別プロファイルの設定を移動しない。その後 VS Code を完全終了する（ウィンドウを閉じるだけではなく Quit）。
3. このリポジトリのルートで、既存ファイルをリポジトリ外に退避する。既存リンクの場合はリンク先を確認してここで止める。
   以下は通常ファイル向けの手動手順で、リンクやバックアップを上書きしない。

   ```sh
   settings="$HOME/Library/Application Support/Code/User/settings.json"
   backup="$HOME/Library/Application Support/Code/settings-backup-$(date +%Y%m%d-%H%M%S)"
   if [ -L "$settings" ]; then
     echo '既存リンクを確認してから移行してください' >&2
   elif [ -f "$settings" ]; then
     (umask 077 && mkdir "$backup") && mv -n "$settings" "$backup/settings.json"
   else
     echo '既存の通常ファイルがありません。パスを確認してください' >&2
   fi
   ```

   バックアップの場所を控え、ファイルが存在すること、元パスが空いたことを確認する。
   バックアップには秘密情報が含まれ得るので公開しない。

4. VS Code だけをリンクする場合は、標準ターゲットのパッケージを限定して実行する。

   ```sh
   make stow-link PACKAGES=vscode
   test -L "$settings" && readlink "$settings"
   ```

   通常の `make stow-link` では他パッケージと一緒に処理される。
   競合があれば Stow は失敗する。`--adopt` や自動削除で既存ファイルを取り込まない。

5. VS Code を起動し、Default Profile の `Preferences: Open User Settings (JSON)` で内容を確認する。
   別プロファイル使用中に既定設定を確認する場合は `Preferences: Open Application Settings (JSON)` を使う。
   編集・UI・AI・YAML の設定と必要な拡張機能、Settings Sync の Settings が OFF のままであることを確認する。
   ワークスペースや別プロファイルの上書きにも注意する。

## 日常の変更とフォーマット

`settings.json` はコメントと末尾カンマを扱える **JSONC**。
`.prettierrc.json` はこのファイルだけに `jsonc` parser を指定し、リポジトリ標準の
`npx prettier@3 --check .` の対象にする。整形は次のように限定できる。

```sh
npx prettier@3 --write 'packages/vscode/Library/Application Support/Code/User/settings.json'
git diff -- 'packages/vscode/Library/Application Support/Code/User/settings.json'
```

リンク中は設定 UI や JSON エディタでの保存によって Git 管理ファイルが変更される可能性がある。
VS Code のファイル書き込み実装はシンボリックリンクに対する atomic write を避けているが、
この PR では GUI 保存を実機検証していない。保存後はリンクが残っていることと `git diff` を確認する。
コミット前には必ず差分を読み、トークン、接続先、個人パス、生成状態を含めない。

## ロールバック

VS Code を完全終了し、このリポジトリのルートで以下を実行する。

```sh
make stow-unlink PACKAGES=vscode
settings="$HOME/Library/Application Support/Code/User/settings.json"
# backup を初回移行で控えた実際のディレクトリに設定し直す
if [ -e "$settings" ] || [ -L "$settings" ]; then
  echo '元パスが空ではありません。上書きせず確認してください' >&2
elif [ -f "$backup/settings.json" ]; then
  mv -n "$backup/settings.json" "$settings"
else
  echo 'バックアップの場所を確認してください' >&2
fi
```

元の通常ファイルが復元されたことを確認して VS Code を起動する。
Settings Sync を戻す場合は復元内容とクラウド側を確認してから Settings を有効にする。
他パッケージには `PACKAGES=vscode` の unlink は作用しない。

## 参照

- [公式: User and workspace settings](https://code.visualstudio.com/docs/configure/settings)
- [公式: Settings Sync の同期カテゴリ](https://code.visualstudio.com/docs/configure/settings-sync#_configure-synced-data)
- [公式: Profiles](https://code.visualstudio.com/docs/configure/profiles)
- [公式: JSON with Comments](https://code.visualstudio.com/docs/languages/json#_json-with-comments)
- [公式ソース: DiskFileSystemProvider の canWriteFileAtomic](https://github.com/microsoft/vscode/blob/main/src/vs/platform/files/node/diskFileSystemProvider.ts)
