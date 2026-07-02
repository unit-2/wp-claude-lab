# [wp-rest-api] REST API 必須ルール

## エンドポイント登録

- `permission_callback` を**必ず**実装する（省略不可）
- 公開エンドポイントは `__return_true` に `// 意図的に公開` コメントを付ける
- 引数は `args` で `validate_callback` / `sanitize_callback` を定義する
- namespace は `myplugin/v1` 形式（プラグインスラッグ + バージョン）

## レスポンス

- 成功: `WP_REST_Response` を返す
- 失敗: `WP_Error` を返す（`new WP_Error( 'code', 'message', [ 'status' => 404 ] )`）
- ステータスコードを必ず指定する

## セキュリティ

- `current_user_can()` で権限チェックを行う
- 入力値は `sanitize_text_field()` / `absint()` 等でサニタイズする
- nonce が必要な場面では `check_ajax_referer()` / `wp_verify_nonce()` を使う

## よくある間違い

- `permission_callback` を省略する → WordPress 5.5+ で警告、将来は動作不可
- 認証なし公開エンドポイントに `__return_true` を無計画に使う
- エラー時に `false` や `null` を返す → 必ず `WP_Error` を返す
