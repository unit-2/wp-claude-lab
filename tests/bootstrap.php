<?php
/**
 * PHPUnit bootstrap file.
 *
 * Brain Monkey のセットアップは各テストクラスの setUp/tearDown で行う。
 * このファイルはオートローダーの読み込みのみ担当する。
 *
 * @see https://brain-wp.github.io/BrainMonkey/docs/wordpress-specific-tools.html
 */

declare(strict_types=1);

require_once dirname( __DIR__ ) . '/vendor/autoload.php';
