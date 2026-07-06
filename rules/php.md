# PHP Coding Style

## 必須確認コマンド

編集時は `.claude/hooks/post-edit-format.sh` が php-lint を自動実行する。
リリース前・PR 前に全体チェックとして以下を手動実行する（`wp-content/` ディレクトリから）：

```bash
# WPCS コーディング規約チェック（<target> は対象のテーマ/プラグインパス）
composer run php-lint <target>

# 自動修正可能な箇所を修正
composer run php-format <target>

# 静的解析（型エラー・未定義変数など）
composer run phpstan <target>

# PHP バージョン互換性チェック
composer run php-compatibility <target>
```

### PHPStan レベル運用ルール

- 現在のレベル：**3**（型チェックあり）
- 既存コードのエラーは `config/phpstan/phpstan-baseline.neon` に逃がしてよい
- **新規コードは baseline への追加を禁止** — 必ず修正する
- レベルアップの目安：3 → 5 → 8（慣れたら徐々に上げていく）

## General

- PHP 8.1+ を前提とする（composer.json の `php: >=8.1` に一致）。8.2+ の機能は対象環境が対応している場合のみ使う。
- `strict_types=1` は**新規クラスファイルのみ**に宣言する。テンプレートファイル・functions.php・WordPress フック関数を含むファイルには付けない（WordPress コア関数が型強制に依存しているため TypeError が発生する場合がある）。

```php
<?php
// クラスファイルのみ OK
declare(strict_types=1);

class MyPlugin_Settings { ... }
```

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Functions | `snake_case` | `get_post_data()` |
| Classes | `PascalCase` | `PostRepository` |
| Constants | `UPPER_SNAKE_CASE` | `MY_PLUGIN_VERSION` |
| Variables | `$snake_case` | `$post_title` |
| Private properties | `$snake_case` | `$this->post_id` |

## Type Declarations

Always add type hints for parameters and return types.

```php
// CORRECT
function get_post_title( int $post_id ): string {
    ...
}

// WRONG
function get_post_title( $post_id ) {
    ...
}
```

## Null Handling

Prefer the nullsafe operator and null coalescing over verbose null checks.

```php
// CORRECT
$title = $post?->post_title ?? '';
$value = $_GET['key'] ?? 'default';

// AVOID
$title = isset( $post ) ? $post->post_title : '';
```

## Arrays

Use short array syntax `[]` always. Never use `array()`.

```php
// CORRECT
$items = [ 'foo', 'bar' ];

// WRONG
$items = array( 'foo', 'bar' );
```

## Immutability

Avoid mutating objects or arrays passed by reference. Return new values instead.

```php
// CORRECT
function add_item( array $items, string $new_item ): array {
    return array_merge( $items, [ $new_item ] );
}

// WRONG
function add_item( array &$items, string $new_item ): void {
    $items[] = $new_item;
}
```

## Error Handling

WordPress の境界（フック・REST API・テンプレート）では `WP_Error` を使う。内部ロジッククラスでは例外を使う。境界をまたぐ場合は変換レイヤーを作る。

```php
// 内部ロジック（クラス内）→ 例外を使う
class PostRepository {
    public function find( int $id ): \WP_Post {
        $post = get_post( $id );
        if ( ! $post instanceof \WP_Post ) {
            throw new \RuntimeException( "Post {$id} not found." );
        }
        return $post;
    }
}

// WordPress の境界（REST API コールバック）→ WP_Error を使う
function myplugin_rest_get_post( \WP_REST_Request $request ): \WP_Post|\WP_Error {
    try {
        return ( new PostRepository() )->find( $request['id'] );
    } catch ( \RuntimeException $e ) {
        // 内部例外を WP_Error に変換して返す
        return new \WP_Error( 'not_found', __( 'Post not found.', 'myplugin' ), [ 'status' => 404 ] );
    }
}

// エラーログ（本番では getMessage() ではなくエラーコードのみ記録）
error_log( sprintf( '[myplugin] Post not found. ID: %d', $id ) );
```

- 本番環境では `$e->getMessage()` にスタックトレースや DB 情報が含まれる場合があるためログに出力しない
- `WP_DEBUG_LOG` の保存先が Web 公開ディレクトリ外であることを確認する

## DocBlocks

Every public method and function must have a DocBlock.

```php
/**
 * Retrieves a post's metadata value.
 *
 * @param int    $post_id  The post ID.
 * @param string $meta_key The meta key to retrieve.
 * @param mixed  $default  Default value if meta not found.
 * @return mixed The meta value or default.
 */
function get_post_meta_value( int $post_id, string $meta_key, mixed $default = null ): mixed {
    $value = get_post_meta( $post_id, $meta_key, true );
    return ( $value !== '' ) ? $value : $default;
}
```

## File Size

- Keep files under 400 lines.
- One class per file.
- Extract helpers into separate utility files when a file exceeds 300 lines.
