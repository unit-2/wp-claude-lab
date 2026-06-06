# WordPress Development Rules

## Direct File Access の防止

すべての PHP ファイル（ブートストラップファイルを除く）の先頭に必ず記述する：

```php
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}
```

これがないと WordPress を経由せず直接 URL アクセスされた場合に、内部パスや DB 情報が漏洩する。

## Coding Standards

- Follow [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/) for PHP, HTML, CSS, and JavaScript.
- Use PHP_CodeSniffer with `WordPress` ruleset (`phpcs --standard=WordPress`).
- Tabs for indentation in PHP (not spaces).
- All functions, classes, and files must have DocBlocks.

## Security (WordPress-Specific)

### Output Escaping — ALWAYS escape before output

```php
// Text
echo esc_html( $variable );

// HTML attributes
echo esc_attr( $variable );

// URLs
echo esc_url( $url );

// Translated strings
echo esc_html__( 'Text', 'textdomain' );

// Raw HTML (only when necessary)
echo wp_kses_post( $html );
```

### Input Sanitization — ALWAYS sanitize on input

```php
$text    = sanitize_text_field( $_POST['field'] );
$email   = sanitize_email( $_POST['email'] );
$int     = absint( $_POST['count'] );
$url     = esc_url_raw( $_POST['url'] );
$html    = wp_kses_post( $_POST['content'] );
```

### Nonces — ALWAYS verify for state-changing actions

```php
// Output nonce in form
wp_nonce_field( 'my_action', 'my_nonce' );

// Verify nonce before processing
if ( ! isset( $_POST['my_nonce'] ) || ! wp_verify_nonce( $_POST['my_nonce'], 'my_action' ) ) {
    wp_die( esc_html__( 'Security check failed.', 'textdomain' ) );
}
```

### Capability Checks — ALWAYS check before privileged operations

```php
if ( ! current_user_can( 'manage_options' ) ) {
    wp_die( esc_html__( 'You do not have permission.', 'textdomain' ) );
}
```

## Database Queries

- **Never** interpolate variables directly into SQL — always use `$wpdb->prepare()`.
- Use WP Query APIs (`WP_Query`, `get_posts`, `get_terms`) over raw SQL when possible.

```php
// WRONG
$wpdb->query( "SELECT * FROM {$wpdb->posts} WHERE post_title = '$title'" );

// CORRECT
$wpdb->get_results(
    $wpdb->prepare( "SELECT * FROM {$wpdb->posts} WHERE post_title = %s", $title )
);
```

## Hooks and Filters

- Prefix all custom hooks with the plugin/theme slug: `myplugin_before_save`.
- Always document hook arguments in DocBlocks.
- Remove hooks in the same place they are added when appropriate.
- Use `__return_true` / `__return_false` helpers instead of anonymous functions for simple filters.

```php
// CORRECT
add_filter( 'myplugin_show_widget', '__return_true' );

// Avoid
add_filter( 'myplugin_show_widget', function() { return true; } );
```

## Internationalization (i18n)

- Every user-facing string must be wrapped in a translation function.
- Always use a consistent text domain matching the plugin/theme slug.
- Never concatenate translated strings — use `printf` / `sprintf` with placeholders.

```php
// CORRECT
printf(
    /* translators: %s: post title */
    esc_html__( 'You are editing: %s', 'textdomain' ),
    esc_html( $post->post_title )
);

// WRONG
echo esc_html__( 'You are editing: ', 'textdomain' ) . esc_html( $post->post_title );
```

## Prefix Everything

All functions, classes, hooks, global variables, and option names must be prefixed with the plugin/theme slug to avoid conflicts.

```php
// CORRECT
function myplugin_register_post_type() { ... }
class MyPlugin_Settings { ... }
update_option( 'myplugin_settings', $data );

// WRONG
function register_post_type() { ... }
update_option( 'settings', $data );
```

## REST API エンドポイント

カスタム REST API エンドポイントには **必ず `permission_callback` を実装する**。省略・`__return_true` の無計画な使用は認証なし公開エンドポイントになる。

```php
// CORRECT — 認証が必要なエンドポイント
register_rest_route( 'myplugin/v1', '/data', [
    'methods'             => WP_REST_Server::CREATABLE,
    'callback'            => 'myplugin_handle_request',
    'permission_callback' => function () {
        return current_user_can( 'edit_posts' );
    },
] );

// CORRECT — 意図的な公開エンドポイント（明示的に記述する）
register_rest_route( 'myplugin/v1', '/public-data', [
    'methods'             => WP_REST_Server::READABLE,
    'callback'            => 'myplugin_get_public_data',
    'permission_callback' => '__return_true', // 意図的に公開
] );

// WRONG — permission_callback の省略（WordPress 5.5 以降は警告、将来は動作不可）
register_rest_route( 'myplugin/v1', '/data', [
    'methods'  => WP_REST_Server::CREATABLE,
    'callback' => 'myplugin_handle_request',
] );
```

## File Organization

- One class per file. File name must match class name in lowercase with hyphens (`class-my-plugin-settings.php`).
- Plugin main file must contain only the plugin header and bootstrapping code.
- Keep template files in a `templates/` directory; load with `locate_template()` or `load_template()`.

## wp_enqueue — Scripts and Styles

- Never use `<script>` or `<link>` tags directly — always use `wp_enqueue_script()` / `wp_enqueue_style()`.
- Set proper dependencies and version numbers.
- Use `wp_localize_script()` or `wp_add_inline_script()` to pass PHP data to JavaScript.

```php
add_action( 'wp_enqueue_scripts', 'myplugin_enqueue_assets' );
function myplugin_enqueue_assets() {
    wp_enqueue_style(
        'myplugin-style',
        plugin_dir_url( __FILE__ ) . 'assets/css/style.css',
        [],
        MYPLUGIN_VERSION
    );
    wp_enqueue_script(
        'myplugin-script',
        plugin_dir_url( __FILE__ ) . 'assets/js/script.js',
        [ 'jquery' ],
        MYPLUGIN_VERSION,
        true
    );
}
```
