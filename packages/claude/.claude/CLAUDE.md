# Claude Code Configuration

## YOU MUST:

- 回答は日本語で行ってください
- そのプロジェクトにフォーマッタやリンターが設定されている場合、チェックが成功することを確認して、コーディング完了としてください。
  - 例えば、package.json がある場合は、npm scripts を確認し、必要なコマンドの結果を確認してください。

### Git ワークフロー

- 作業を始める際は必ずブランチを切る
- コミット前に lint/fmt などが通ることを確認する
- **実装完了後、PR 作成前に `codex-review` Skill を呼び出し、Codex によるクロスレビューを実施する**
  - critical の指摘があれば修正してからコミットする
  - warning はユーザーに確認してから対応を決める
- 作業完了後はコミットして PR を作成する
- PR の description は日本語で記載する
- ユーザーから明示的に issue 番号を指定された場合のみ、PR description の先頭に `close #<issue番号>` を記載する。issue 番号が指定されていない場合は記載しない。Issue の作成・コメントには close キーワードを使わない

### CI/CD

- PR を作成した後は、必ず CI の状態を確認する
- CI が失敗した場合は、ログを確認して修正する
- CI が開始されない場合は、ブランチのコンフリクトが原因の可能性がある。コンフリクトを解消してから再度確認すること。

### ブラウザ操作（Lightpanda + agent-browser）

ブラウザ操作には Lightpanda（ヘッドレスブラウザ）と agent-browser CLI を組み合わせて使用する。

起動手順:

1. `lightpanda serve --host 127.0.0.1 --port 9222` — Lightpanda を CDP サーバーとして起動
2. `agent-browser --cdp 9222 <command>` — agent-browser から Lightpanda に接続して操作

基本ワークフロー:

1. `agent-browser --cdp 9222 open <url>` — ページを開く
2. `agent-browser --cdp 9222 snapshot -i` — インタラクティブ要素の ref を取得
3. `agent-browser --cdp 9222 click @<ref>` / `agent-browser --cdp 9222 fill @<ref> "値"` — 要素を操作
4. `agent-browser --cdp 9222 screenshot <file>` — スクリーンショット撮影
5. `agent-browser --cdp 9222 close` — ブラウザを閉じる

主要コマンド:

- ナビゲーション: open, back, forward, reload
- 要素操作: click, fill, type, press, hover, select, check, scroll
- 情報取得: get text, get html, get value, get title, get url
- 状態確認: is visible, is enabled, is checked
- デバッグ: console, errors, screenshot, snapshot
- ネットワーク: network requests
- タブ管理: tabs list, tabs new, tabs close, tabs select

### Codex 委譲

- 実装・修正・テスト・PR 作成の依頼では、以下の条件を満たす場合に Codex へ委譲する。
  - 目的、制約、受け入れ条件が明示されている
  - 変更対象ファイルまたは対象ディレクトリが明示されている
- 委譲時は `codex-delegate` Skill を使い、仕様を整理して `codex exec` を実行すること。
- Codex 実行結果として、最低限以下を返すこと。
  - 変更ファイル一覧
  - 実行した検証コマンドと結果
  - コミット SHA
  - PR URL
