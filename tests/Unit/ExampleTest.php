<?php
/**
 * ユニットテストのサンプル。
 *
 * 実際のテストを書くときはこのファイルを参考にして、
 * tests/Unit/<テーマ名 or プラグイン名>/ 以下に配置する。
 *
 * 例: tests/Unit/my-plugin/Service/PostServiceTest.php
 */

declare(strict_types=1);

namespace WpClaudeLab\Tests\Unit;

use Brain\Monkey;
use Brain\Monkey\Functions;
use PHPUnit\Framework\TestCase;

class ExampleTest extends TestCase {

	protected function setUp(): void {
		parent::setUp();
		Monkey\setUp();
	}

	protected function tearDown(): void {
		Monkey\tearDown();
		parent::tearDown();
	}

	public function test_brain_monkey_can_mock_wordpress_functions(): void {
		Functions\when( 'get_the_title' )->justReturn( 'Hello World' );

		$this->assertSame( 'Hello World', get_the_title( 1 ) );
	}

	public function test_esc_html_mock(): void {
		Functions\when( 'esc_html' )->returnArg();

		$this->assertSame( '<script>', esc_html( '<script>' ) );
	}
}
