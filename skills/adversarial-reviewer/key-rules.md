# [adversarial-reviewer] コミット前 確認必須チェックリスト

## ロジック

- 条件の逆転・`!` の付け忘れはないか
- null チェック漏れ・オフバイワンはないか
- 早期リターンの条件が正しいか

## セキュリティ

- 出力に `esc_html()` / `esc_attr()` / `esc_url()` が漏れていないか
- 状態変更処理に `wp_verify_nonce()` があるか
- `current_user_can()` で権限チェックをしているか

## WordPress

- `$wpdb->prepare()` なしの SQL がないか
- 関数・フック・オプション名にプレフィックスが付いているか
- `if ( ! defined( 'ABSPATH' ) ) { exit; }` がすべての PHP ファイルにあるか

## 型安全

- 型宣言・戻り値型が揃っているか
- `composer run phpstan <target>` がエラーゼロか

## 確認完了後

```bash
touch /tmp/wp-review-ok-$(echo "$PWD" | md5 -q 2>/dev/null || echo "$PWD" | md5sum | cut -c1-8)
git commit -m "..."
```
