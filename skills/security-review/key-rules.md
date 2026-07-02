# [security-review] セキュリティ確認 必須ルール

## 出力エスケープ（常に必須）

- テキスト: `esc_html()` / `esc_html__()`
- HTML属性: `esc_attr()`
- URL: `esc_url()`
- 生HTML: `wp_kses_post()`

## 入力サニタイズ（常に必須）

- テキスト: `sanitize_text_field()`
- 数値: `absint()`
- メール: `sanitize_email()`
- URL: `esc_url_raw()`

## 認証・権限

- `current_user_can()` で権限チェックを行う
- 状態変更操作には `wp_verify_nonce()` を必ず検証する
- REST API には `permission_callback` を必ず実装する

## データベース

- `$wpdb->prepare()` を必ず使う（文字列結合での SQL 構築は禁止）
- ユーザー入力を直接クエリに渡さない

## 機密情報

- シークレット・APIキー・パスワードをコードにハードコードしない
- `wp-config.php` で定義して `defined()` で参照する
- エラーメッセージに内部パス・DB情報を含めない

## よくある間違い

- `echo $_POST['key']` → 必ずサニタイズ＋エスケープを通す
- nonce の検証漏れ → フォーム・AJAX・REST すべてで確認
- `manage_options` 以外の適切な capability を使っていない
