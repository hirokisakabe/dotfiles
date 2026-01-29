---
name: worktree
description: 新しいgit worktreeを作成し、.envファイルをコピーして作業を開始する。ユーザーがタスクを説明したら、適切なブランチ名を決定してworktreeを作成する。
---

# Git Worktree 作成スキル

新しい git worktree を作成し、開発環境をセットアップする。

## 使い方

```
/worktree <タスクの説明>
```

例:

- `/worktree ユーザー認証機能を追加`
- `/worktree issue #123 のバグ修正`
- `/worktree READMEの更新`

## 実行手順

1. **ブランチ名の決定**
   - タスクの説明から適切なブランチ名を決定する
   - 命名規則: `feature/xxx`, `fix/xxx`, `docs/xxx` など
   - 英語、ケバブケース、簡潔に（例: `feature/add-user-auth`, `fix/login-bug`）

2. **メインworktreeのパスを取得**
   ```bash
   git worktree list | head -1 | awk '{print $1}'
   ```

3. **新しいworktreeを作成**
   ```bash
   # メインworktreeのディレクトリと同階層に作成
   git worktree add -b <ブランチ名> ../<ブランチ名> main
   ```

4. **環境ファイルのコピー**
   メインworktreeから以下のファイルが存在すればコピー:
   - `.env`
   - `.env.local`
   - `.env.development.local`

   ```bash
   # 例: .env のコピー
   cp <メインworktreeパス>/.env ../<ブランチ名>/.env
   ```

5. **新しいworktreeに移動**
   ```bash
   cd ../<ブランチ名>
   ```

6. **完了メッセージ**
   以下を表示:
   - 作成したブランチ名
   - worktree のパス
   - コピーした環境ファイル
   - 「作業を開始できます」というメッセージ

## 注意事項

- 既に同名のブランチが存在する場合はエラーになるので、ユーザーに確認する
- .env ファイルは .gitignore に含まれているため、コピーしても git には追跡されない
- worktree 作成後は自動的にそのディレクトリに移動するので、そのまま作業を続けられる
