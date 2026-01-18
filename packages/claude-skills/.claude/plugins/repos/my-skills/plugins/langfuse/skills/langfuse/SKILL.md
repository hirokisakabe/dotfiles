---
name: langfuse
description: Langfuseのトレース、ログ、observability、モニタリングデータを取得・表示する。ユーザーが「Langfuseのログを見せて」「トレースを確認」「観測データを取得」などと言ったときに使用する。
---

# Langfuse Traces Skill

Langfuse APIからトレースログを取得して表示する。

## パラメータ

- `limit`: 取得件数（デフォルト: 5）
- `environment`: フィルタする環境（production / development）

例:

- `/langfuse` - 直近5件を取得
- `/langfuse 10` - 直近10件を取得
- `/langfuse production` - production環境のみ

## 実行手順

1. 以下のNode.jsコードを実行してトレースを取得:

```javascript
require("dotenv").config();
const publicKey = process.env.LANGFUSE_PUBLIC_KEY;
const secretKey = process.env.LANGFUSE_SECRET_KEY;
const baseUrl = process.env.LANGFUSE_BASE_URL;

const auth = Buffer.from(publicKey + ":" + secretKey).toString("base64");
const limit = ${LIMIT}; // パラメータから取得

fetch(baseUrl + "/api/public/traces?limit=" + limit, {
  headers: { "Authorization": "Basic " + auth }
})
.then(r => r.json())
.then(data => console.log(JSON.stringify(data, null, 2)))
.catch(e => console.error("Error:", e));
```

2. 取得結果を以下の形式でサマリー表示:

| 時刻 | 環境 | ユーザー入力 | レイテンシ | コスト |
| ---- | ---- | ------------ | ---------- | ------ |
| ...  | ...  | ...          | ...        | ...    |

3. 追加情報として以下も表示:
   - 総トレース数（meta.totalItems）
   - 取得したトレースのID一覧

## 詳細取得

特定のトレースの詳細を見たい場合は、トレースIDを指定して以下のエンドポイントを呼び出す:

```
GET /api/public/traces/{traceId}
```

## 環境変数

以下の環境変数が `.env` に設定されている必要がある:

- `LANGFUSE_PUBLIC_KEY`
- `LANGFUSE_SECRET_KEY`
- `LANGFUSE_BASE_URL`
