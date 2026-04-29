---
name: issue-implement
description: GitHub issue 番号を起点に、実装 → cross-review → 受け入れ条件チェック → commit → PR 作成 → CI 確認まで一気通貫で進める。ユーザーから「issue #N を実装して」「#N お願い」などの依頼があった場合に使用する。
---

# Issue Implement Skill

GitHub issue を起点とした issue-driven 開発サイクルの中核 skill。issue 番号を受け取り、Status 確認から PR 作成・CI 確認までを定型的に実行する。

## 依存

- **`codex-review` skill**: 実装後の cross-review に必須。Codex CLI (`codex` コマンド) が未導入の場合は明確に失敗させ、`brew install --cask codex` の案内を行う（`codex-review` skill 側の失敗時対応に従う）。
- **`acceptance-check` skill**: cross-review 後・commit 前に受け入れ条件の自動検査を実施する。
- **`gh` CLI**: GitHub 操作全般に使用する。

## スコープ

- **含む**: Status 確認、Depends on の close 確認、親 issue の文脈取り込み、実装、cross-review、受け入れ条件チェック、commit、PR 作成、CI 確認・修正。
- **含まない**: branch / worktree 状態の検査。default branch 名はリポジトリにより異なる (main / master / develop / trunk 等) ため、特定の branch を仮定したガードは行わない。「適切な作業環境にいる」ことは caller (ユーザー / harness) の責任。

## 実行手順

### 1. issue の取得と Status 確認

```bash
ISSUE_NUMBER=<issue 番号>
gh issue view "$ISSUE_NUMBER"
```

- 本文先頭の `Status:` を確認する。
  - **`Status: Ready`**: 続行。
  - **`Status: Draft`**: 着手しない。ユーザーに方針確認を促し、必要なら `issue-refine` skill で整理する。
  - **`Status:` 表記なし / フォーマット不完全**: `issue-refine` skill での整理を案内する。

### 2. Depends on (依存 issue) の確認

issue 本文に `Depends on:` 行がある場合、列挙された依存 issue がすべて close 済みかを確認する。

- 抽出: `gh issue view "$ISSUE_NUMBER"` の出力から `Depends on:` で始まる行をパースし、`#<数字>` を列挙する。
- 判定は **本文の状態表記ではなく `gh issue view <番号> --json state` の実体で行う**。本文に状態を書き写さない設計（issue-create 側）と整合させ、表記漏れの影響を受けないため。

```bash
gh issue view <依存 issue 番号> --json state --jq '.state'
# → "OPEN" or "CLOSED"
```

- **1 件でも `OPEN` の場合**: 着手しない。どの依存 issue が未 close かをユーザーに報告し、判断（先に依存を片付ける / 強行する / 中止）を仰ぐ。
- **すべて `CLOSED` の場合**: 次のステップへ進む。
- **`Depends on:` 行が無い場合**: 何もせず次のステップへ進む。

### 3. 親 issue の確認

issue 本文に `親: #<番号>` の記載、または GitHub の sub-issue として親が存在する場合は、必ず親 issue を `gh issue view` で取得し、文脈を踏まえる。

```bash
# 親 issue が本文に記載されている場合
gh issue view <親 issue 番号>

# sub-issue として登録されているかの確認 (任意)
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
gh api "repos/${REPO}/issues/${ISSUE_NUMBER}" --jq '.parent // empty'
```

### 4. 実装

issue の「実装方針」「受け入れ条件」「スコープ外」に従い実装する。実装中に方針の揺らぎや不明点が出た場合は、勝手に拡張せずユーザーに確認する。

実装完了の判定は **受け入れ条件のチェックリストをすべて満たしていること**。

### 5. lint / format / 型チェック

プロジェクトに設定されているフォーマッタ・リンタ・型チェックを実行し、すべてパスすることを確認する。これらが通らない場合は実装完了とみなさない。

### 6. cross-review (codex-review skill)

`codex-review` skill を呼び出して Codex CLI による cross-review を実施する。

- **critical** の指摘がある場合: 修正してから次に進む。
- **warning** の指摘がある場合: Claude 自身で対応要否を判断する。妥当な指摘は自律的に修正し、見送る場合は理由を添えて報告する（ユーザー確認は不要）。
- **info** のみの場合: 指摘を共有し、commit に進む。

> **注意**: 現状 `codex-review` skill は base branch を `main` 固定で扱う。default branch が `main` 以外のリポジトリ（`master` / `develop` / `trunk` 等）では差分取得や `--base` 指定が破綻する可能性がある。本 skill 自体は branch 名を仮定しないが、依存先のこの制約は引き継ぐ。本格的な配布対象になった段階で `codex-review` 側の base branch 動的化を検討する。

### 7. 受け入れ条件チェック (acceptance-check skill)

`acceptance-check` skill を呼び出し、issue 本文の `## 受け入れ条件` を抽出して各項目を自動検査する。

- **`✗` が 1 件でもある場合**: 受け入れ条件未達。commit に進まず実装に戻って修正する。
- **`?` (要人間判定) のみの場合**: Claude 自身で動作確認方法を実行できる範囲は実行し、ブラウザ操作や主観評価など人間判定が必要なものは判断結果を添えて進む。判断が困難なものはユーザーに確認する。
- **すべて `✓` の場合**: そのまま commit に進む。

`acceptance-check` 自体は read-only であり、issue body や code を変更しない。failed 項目の修正は本 skill 側の責任。

### 8. commit

Conventional Commit-like prefix (`feat:` / `fix:` / `chore:` 等) を使用し、scope を絞った具体的なメッセージで commit する。

### 9. PR 作成

```bash
gh pr create --title "<title>" --body-file - <<'EOF'
<日本語の description>
EOF
```

- **PR description は日本語**で記載する（CLAUDE.md の常時適用ルール）。
- ユーザーから明示的に issue 番号を指定された場合のみ、description の先頭に `close #<issue 番号>` を記載する。本 skill のように issue 番号を起点に呼ばれた場合は、その issue 番号を「明示指定」とみなして `close #<issue 番号>` を入れてよい。
- description には目的、影響パッケージパス、ローカル検証手順を含める。

### 10. CI 確認

```bash
gh pr checks <PR 番号 or URL> --watch
```

- CI が成功するまで監視する。
- **失敗した場合**: ログを確認して修正し、追加 commit で対応する。
- **CI が開始されない場合**: ブランチのコンフリクトが原因の可能性が高い。`gh pr view` でコンフリクト状況を確認し、解消してから再度 CI を待つ。

### 11. 完了報告

PR URL と CI 結果（成功 / 修正後成功）をユーザーに返す。

## やらないこと

- branch / worktree の状態チェック（default branch 名を仮定したガードを含む）。
- issue 本文や PR への `close` キーワードの自動付与（ユーザー明示指定時のみ）。
- 受け入れ条件を満たさない状態での PR 作成。
- Codex CLI 未導入時の cross-review 省略（`codex-review` skill の失敗時対応に従い、明確に失敗させる）。
