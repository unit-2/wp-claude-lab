# テスト方針

## テストフレームワーク

| 用途 | ツール |
|------|--------|
| PHP ユニットテスト | [PHPUnit](https://phpunit.de/) ^10 |
| WordPress 関数のモック | [Brain Monkey](https://brain-wp.github.io/BrainMonkey/) (`brain/monkey`) ^2 |
| モック全般 | [Mockery](https://docs.mockery.io/) ^1 |
| ブロック（JavaScript） | Jest（`@wordpress/scripts` に同梱）|
| E2E | [Playwright](https://playwright.dev/)（重要なフローのみ） |

これらは `composer.json` の `require-dev` に含まれています。インストール：

```bash
composer install
```

## カバレッジ目標

| 対象 | 目標 |
|------|------|
| ビジネスロジック層（Repository・Service・Validator クラス） | 80%+ |
| WordPress フック登録・テンプレート | 対象外（モックのコストが高い）|
| REST API ハンドラー | クリティカルパスのみ |

> **注意:** WordPress 統合テスト（実際の DB を使う）は遅いため、ユニットテスト（Brain Monkey でモック）を中心に書く。

## 基盤スクリプト自体のテスト

`.claude/hooks/` や `bin/` のシェルスクリプト、`skills/wp-project-triage/scripts/detect_wp_project.mjs` は
テーマ・プラグインのビジネスロジックとは別の「基盤スクリプト」として扱う。

- `detect_wp_project.mjs` は `node --test` でテストする（実装は handoff/01 で完了済み）
- `.claude/hooks/*.sh` と `bin/wp-review.sh` は [bats-core](https://bats-core.readthedocs.io/) でテストする
  （`tests/hooks/*.bats`）。bats はリポジトリにベンダリングせず、`brew install bats-core` /
  `npm i -g bats` で各自の開発環境に用意する前提とする
- 実行コマンド:
  ```bash
  node --test "tests/**/*.test.mjs"   # detect_wp_project.mjs 等
  composer run test:hooks             # bats 未導入なら案内を出してスキップする
  ```
- 「カバレッジ 80%+」（下記）はテーマ・プラグインのビジネスロジック層に適用される目標であり、
  基盤スクリプトについては全フックにスモークテスト（正常系・代表的な異常系）があることを基準とする

> **メモ（01実施時に判明・Node v22.16.0 で確認済み）**: `node --test` は引数にグロブ記号
> （`*` 等）を含まない**リテラルなディレクトリパス**を渡すと `MODULE_NOT_FOUND` で失敗する
> （Node がテストランナーのグロブ探索ではなく通常のモジュール読み込みとして扱うため）。
> `node --test tests/hooks/` のようなディレクトリ直指定ではなく、上記のようにグロブ指定するか、
> 対象ディレクトリを cwd にして引数なしで実行すること。

## テスト駆動開発（TDD）

1. テストを先に書く（RED）
2. テストを実行 → 失敗することを確認
3. 最小限の実装（GREEN）
4. テストを実行 → 成功することを確認
5. リファクタリング（IMPROVE）

## Brain Monkey によるユニットテスト

```php
use Brain\Monkey;
use Brain\Monkey\Functions;

class MyServiceTest extends \PHPUnit\Framework\TestCase {
    protected function setUp(): void {
        parent::setUp();
        Monkey\setUp();
    }

    protected function tearDown(): void {
        Monkey\tearDown();
        parent::tearDown();
    }

    public function test_get_title_returns_escaped_string(): void {
        Functions\when( 'get_the_title' )->justReturn( '<script>alert(1)</script>' );
        Functions\when( 'esc_html' )->returnArg();

        $service = new MyService();
        $result  = $service->getTitle( 1 );

        $this->assertSame( '<script>alert(1)</script>', $result );
    }
}
```

## テスト失敗時の対処

1. `wp-phpstan` スキルで型エラーを確認
2. テストの独立性を確認（`setUp`/`tearDown` で状態をリセット）
3. モックが正しいか確認
4. テストではなく**実装を修正**する（テストが仕様）

## 実行コマンド

```bash
# 全テスト実行
composer run test

# 特定のテストのみ
composer run test -- --filter=MyServiceTest

# カバレッジレポート生成（Xdebug または PCOV が必要）
composer run test -- --coverage-text

# 基盤スクリプト（.claude/hooks/*.sh・bin/wp-review.sh）のテスト
composer run test:hooks
```
