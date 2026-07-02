# [wp-wpcli-and-ops] WP-CLI 実行前チェック

## 実行前の確認

- 本番環境では `--dry-run` で先に結果を確認してから実行する
- `search-replace` は必ず `--dry-run` を先に実行する
- Local 環境では system の `wp` コマンドは使えない。Local の PHP パスを使う
  → `skills/wp-wpcli-and-ops/references/local-environment.md` を参照

## よく使うコマンド

```bash
# DB エクスポート（バックアップ）
wp db export backup.sql

# URL 置換（--dry-run で先に確認）
wp search-replace 'http://old.example.com' 'https://new.example.com' --dry-run
wp search-replace 'http://old.example.com' 'https://new.example.com'

# キャッシュ削除
wp cache flush
wp rewrite flush

# プラグイン操作
wp plugin list
wp plugin activate my-plugin
```

## よくある間違い

- `search-replace` を `--dry-run` なしで即実行する → 取り消せない
- 本番で `--allow-root` を使う → 権限設計を見直す
- Local 環境でシステムの `wp` コマンドを使う → パスが合わず動かない
