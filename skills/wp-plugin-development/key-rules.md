# [wp-plugin-development] フック注入用ルールサマリー

## ファイル構成の必須ルール

- プラグインヘッダー（`Plugin Name:` 等）は **main ファイルのみ**に書く
- すべての PHP ファイルの先頭に `if ( ! defined( 'ABSPATH' ) ) { exit; }`
- ファイル名: `class-my-plugin-name.php`（クラス名と対応）
- 1ファイル1クラス、400行以内を目安に分割する

## フック・命名の必須ルール

- 関数・クラス・フック名・オプション名すべてにプラグインスラッグをプレフィックス
- `add_action` / `add_filter` は init より遅いフックで登録（`plugins_loaded` 推奨）
- activation: `register_activation_hook( __FILE__, 'myplugin_activate' )`
- uninstall: `uninstall.php` でデータ削除処理を必ず実装する

## セキュリティ必須

```php
// Nonce 検証（状態変更アクションは必須）
if ( ! wp_verify_nonce( $_POST['_wpnonce'], 'myplugin_action' ) ) {
    wp_die( esc_html__( 'Security check failed.', 'myplugin' ) );
}

// 権限チェック
if ( ! current_user_can( 'manage_options' ) ) {
    wp_die( esc_html__( 'Permission denied.', 'myplugin' ) );
}

// DB クエリ
$wpdb->get_results( $wpdb->prepare( "SELECT * FROM {$wpdb->posts} WHERE ID = %d", $id ) );
```

## よくある間違い

- `$_POST` / `$_GET` をそのまま使う → 必ず sanitize_text_field() 等でサニタイズ
- `update_option()` のキーにプレフィックスなし → 他プラグインと衝突する
- `uninstall.php` を作らない → アンインストール後にゴミデータが残る
