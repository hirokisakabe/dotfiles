---
name: codex-delegate
description: 実装・修正・テスト・PR作成タスクを Codex CLI へ委譲する。ユーザーが「実装して」「修正して」「PRまで」などを依頼し、仕様が確定している場合に使用する。
---

# Codex Delegate Skill

実装作業を Claude Code から Codex CLI へ委譲するための手順。

## 利用条件

- ユーザー要求が実装、修正、テスト実行、または PR 作成を含む
- 以下が確定している
  - 目的
  - 制約
  - 受け入れ条件
  - 変更対象ファイルまたは対象ディレクトリ

## 実行手順

1. ユーザー要求を以下の形式で短く整理する。

```md
# Task
- 目的:
- 背景:

# Scope
- In:
- Out:

# Constraints
- 変更禁止:
- 互換性要件:
- 実行必須コマンド:

# Acceptance Criteria
1.
2.
3.

# Target Files
- path:
```

2. 整理した内容を使い、`codex exec` で実装を委譲する。

```bash
codex exec "Implement the task in the current repository. Follow repository instructions. Run required lint/format/test checks. Create a branch, commit changes, open a PR, and report changed files, verification commands, commit SHA, and PR URL."
```

3. Codex の結果を確認し、次の形式で要約して返す。
   - 変更ファイル一覧
   - 実行コマンドと結果
   - コミット SHA
   - PR URL
   - 未解決事項（ある場合）

## 失敗時の対応

- 仕様が不足している場合は実装を開始せず、不足項目を列挙してユーザーへ確認する。
- `codex` コマンドが見つからない場合は `which codex` で確認し、未導入であることとインストール手順を案内する。
- CI が失敗した場合は失敗ログ要約と修正方針を提示する。
