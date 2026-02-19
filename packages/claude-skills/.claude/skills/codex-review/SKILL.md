---
name: codex-review
description: 実装完了後、PR作成前に Codex CLI へコードレビューを委譲する。Claude Code が自身の実装に対してセカンドオピニオンを得るために使用する。
---

# Codex Review Skill

実装済みの変更を Codex CLI にレビューさせ、異なる視点からのフィードバックを得る。

## 利用タイミング

- Claude Code による実装が完了した後、PR 作成前に呼び出す
- ユーザーが明示的にレビューを依頼した場合

## 実行手順

1. 現在のブランチの差分を確認する。

```bash
git diff main --stat
git diff main
```

2. 差分の概要を整理し、`codex exec` でレビューを委譲する。

```bash
codex exec "Review the uncommitted or recently committed changes on the current branch compared to main. Evaluate from these perspectives:

1. **Readability**: Are variable/function names clear? Is the intent obvious?
2. **Bugs**: Are there edge cases, null/undefined handling issues, or logic errors?
3. **Performance**: Are there unnecessary re-computations, N+1 queries, or inefficient patterns?
4. **Security**: Is there proper input validation? Are secrets or credentials exposed?
5. **Tests**: Is test coverage adequate for the changes?

Output format:
- List each finding with severity (critical / warning / info)
- For each finding, include the file path, line range, and a concrete suggestion
- If no issues found, state that the code looks good
- End with a summary: total findings by severity"
```

3. Codex のレビュー結果を確認し、ユーザーへ報告する。
   - **critical** の指摘がある場合: 修正案を提示し、ユーザーに対応方針を確認する
   - **warning** の指摘がある場合: 指摘内容を一覧で示し、対応要否を確認する
   - **info** のみの場合: 指摘を共有し、PR 作成に進む

## 失敗時の対応

- `codex` コマンドが見つからない場合は `which codex` で確認し、未導入であることとインストール手順を案内する。
- 差分がない場合はレビュー不要としてスキップする。
