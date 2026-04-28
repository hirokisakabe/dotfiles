# Claude Code Configuration

## YOU MUST:

- そのプロジェクトにフォーマッタやリンターが設定されている場合、チェックが成功することを確認して、コーディング完了としてください。
  - 例えば、package.json がある場合は、npm scripts を確認し、必要なコマンドの結果を確認してください。

### Git ワークフロー（常時適用）

- コミット前に lint/fmt などが通ることを確認する
- PR の description は日本語で記載する
- ユーザーから明示的に issue 番号を指定された場合のみ、PR description の先頭に `close #<issue番号>` を記載する

> issue 起点の実装サイクル（Status 確認 → cross-review → commit → PR → CI 確認）は `issue-implement` skill に委譲する。サイクル固有の手順は本ファイルに記載しない。

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
