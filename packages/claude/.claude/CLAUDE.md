# Claude Code Configuration

## YOU MUST:

- そのプロジェクトにフォーマッタやリンターが設定されている場合、チェックが成功することを確認して、コーディング完了としてください。
  - 例えば、package.json がある場合は、npm scripts を確認し、必要なコマンドの結果を確認してください。

### Git ワークフロー

- コミット前に lint/fmt などが通ることを確認する
- **実装完了後、PR 作成前に `codex-review` Skill を呼び出し、Codex によるクロスレビューを実施する**
  - critical の指摘があれば修正してからコミットする
  - warning は Claude 自身で対応要否を判断し、必要なら修正する（ユーザー確認は不要）
- 作業完了後はコミットして PR を作成する
- PR の description は日本語で記載する
- ユーザーから明示的に issue 番号を指定された場合のみ、PR description の先頭に `close #<issue番号>` を記載する

### CI/CD

- PR を作成した後は、必ず CI の状態を確認する
- CI が失敗した場合は、ログを確認して修正する
- CI が開始されない場合は、ブランチのコンフリクトが原因の可能性がある。コンフリクトを解消してから再度確認すること。

### ブラウザ操作（Lightpanda + agent-browser）

ブラウザ操作は `agent-browser` Skill を `--engine lightpanda` 付きで使用する。

```bash
agent-browser --engine lightpanda <command>
```

詳細は `~/.claude/skills/agent-browser/SKILL.md` を参照。

### 最新情報の参照

- バージョン・仕様・状況が変わりうる技術トピックは、知識ベースで答えず WebSearch / WebFetch で必ず確認する。
- ユーザー発話に「最新」「現在」「公式」「リリース」等のキーワードが含まれる場合は検索必須。
- 自分の知識に確信がない技術トピックは、ユーザーから指摘される前に先回りして検索する。
- 出典は markdown リンクで明示する。
