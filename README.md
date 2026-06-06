# WordPress 開発ベース環境

WordPress テーマ・プラグイン・ブロック開発のための共通ベース環境です。  
チームで共有し、あらゆる WordPress 開発の起点として使います。

## 含まれているもの

| 機能 | 内容 |
|------|------|
| PHP コード規約チェック | WordPress Coding Standards (PHPCS) |
| PHP 静的解析 | PHPStan（レベル3スタート） |
| PHP バージョン互換チェック | PHPCompatibilityWP |
| PHP テスト | PHPUnit + Brain Monkey（WordPress 関数モック）|
| Git 保護フック | main/master への直接コミット・push を警告 |
| エディタ設定 | EditorConfig（インデント・改行コードの統一） |
| Claude スキル | WordPress 開発用 17スキル |
| Claude ルール | WordPress / PHP / セキュリティ / テスト / Git |
| 自動 Hook | PHP 編集後に php-lint を自動実行 |

## 必須環境

- [Local by Flywheel](https://localwp.com/)（または任意のローカル WordPress 環境）
- [Composer](https://getcomposer.org/) `brew install composer`
- [Claude Code](https://docs.anthropic.com/ja/docs/claude-code/overview)（`npm install -g @anthropic-ai/claude-code`）

## セットアップ（初回のみ）

### 1. リポジトリをクローン

```bash
git clone <repository-url> wp-content
cd wp-content
```

### 2. PHP ツールをインストール

```bash
composer install
```

### 3. ローカル設定ファイルを作成

```bash
cp CLAUDE.local.md.example CLAUDE.local.md
```

`CLAUDE.local.md` を開いて、自分のローカル環境情報（サイト URL など）を書き込みます。

### 4. Git フックを有効化

```bash
git config core.hooksPath .githooks
```

main / master への直接コミット・プッシュ時に警告が出るようになります。

### 5. Claude Code 用のフック設定をコピー

```bash
cp .claude/settings.json.example .claude/settings.json
```

PHP ファイルを編集したときに自動で lint が走るようになります。

### 5. Local でサイトを立ち上げる

既存の wp-content ディレクトリと差し替えるか、新規サイトの wp-content として使用します。

## 使い方

### PHP コードのチェック

`wp-content/` ディレクトリから実行します。  
`<target>` には対象のテーマまたはプラグインのパスを指定します。

```bash
# 規約チェック
composer run php-lint <target>

# 自動修正
composer run php-format <target>

# 静的解析
composer run phpstan <target>

# PHP バージョン互換性チェック（リリース前）
composer run php-compatibility <target>

# テスト実行
composer run test
```

**例：**

```bash
composer run php-lint themes/my-theme
composer run phpstan plugins/my-plugin
```

### Claude Code での開発

`wp-content/` ディレクトリで Claude Code を起動すると、以下が自動で適用されます：

- PHP ファイルを編集するたびに `php-lint` が自動実行される
- WordPress 開発ルール（`rules/`）が読み込まれる
- 作業内容に応じた専門スキル（`skills/`）が参照される

## ディレクトリ構成

```
wp-content/
├── themes/                    ← テーマ（FSE / クラシック）
├── plugins/                   ← プラグイン（自作のみ管理対象）
├── rules/                     ← Claude 向けルール定義
│   ├── wordpress.md           ← WordPress 固有ルール
│   ├── php.md                 ← PHP コーディングスタイル
│   ├── security.md            ← セキュリティルール
│   ├── testing.md             ← テスト方針
│   └── git-workflow.md        ← コミット・PR の作法
├── skills/                    ← Claude 向けスキル（17種）
│   ├── wp-block-themes/       ← FSE・theme.json・Site Editor
│   ├── wp-block-development/  ← ブロック開発
│   ├── wp-plugin-development/ ← プラグイン開発
│   ├── wp-wpcli-and-ops/      ← WP-CLI 操作
│   ├── wp-rest-api/           ← REST API 開発
│   ├── wp-interactivity-api/  ← Interactivity API
│   ├── wp-performance/        ← パフォーマンス改善
│   ├── wp-phpstan/            ← PHPStan 静的解析
│   ├── wp-playground/         ← WordPress Playground
│   ├── wp-project-triage/     ← 案件の進め方・方針判断
│   ├── wp-abilities-api/      ← Capabilities API
│   ├── wordpress-router/      ← ルーティング
│   ├── wpds/                  ← WordPress Design System
│   ├── adversarial-reviewer/  ← バグ・脆弱性の厳格レビュー
│   ├── security-review/       ← セキュリティチェック
│   ├── tdd-workflow/          ← テスト駆動開発
│   └── agent-browser/         ← ブラウザ自動操作・UI 確認
├── config/
│   ├── phpcs/phpcs.xml.dist   ← PHPCS 設定
│   └── phpstan/               ← PHPStan 設定 + ベースライン
├── composer.json              ← PHP ツール定義
├── composer.lock              ← バージョン固定（要コミット）
├── .githooks/                 ← Git フック（main/master 保護）
├── phpunit.xml.dist           ← PHPUnit 設定
├── .editorconfig              ← エディタ共通設定
├── AGENTS.md                  ← Claude 向け指示書（= .claude/CLAUDE.md）
├── CLAUDE.local.md.example    ← ローカル設定テンプレート
└── CLAUDE.local.md            ← 自分のローカル設定（gitignore済み）
```

## Git 管理対象外のファイル

以下はコミットされません：

| パス | 理由 |
|------|------|
| `vendor/` | Composer の依存関係（`composer install` で再生成可能）|
| `uploads/` | メディアファイル |
| `languages/` | WordPress 翻訳ファイル |
| `themes/twenty*/` | デフォルトテーマ |
| `plugins/*/vendor/` | プラグインの依存関係 |
| `.claude/settings.json` | 個人のフック設定（`.example` からコピーして使う）|
| `phpunit.xml` | PHPUnit ローカル設定（`.dist` からコピーして使う場合）|
| `CLAUDE.local.md` | 個人のローカル設定 |

## 新しいテーマ・プラグインを始めるとき

1. `themes/` または `plugins/` に新しいディレクトリを作る
2. Claude Code で開発を開始する
3. PHP を書いたら自動で `php-lint` が走る
4. 完了前に `composer run phpstan <target>` を実行する

## スキル一覧（17種）

| スキル | 用途 |
|--------|------|
| `wp-block-themes` | FSE・theme.json・Site Editor |
| `wp-block-development` | ブロック開発（block.json 等）|
| `wp-plugin-development` | プラグイン開発 |
| `wp-wpcli-and-ops` | WP-CLI 操作 |
| `wp-rest-api` | REST API 開発 |
| `wp-interactivity-api` | Interactivity API |
| `wp-performance` | パフォーマンス改善 |
| `wp-phpstan` | PHPStan 静的解析 |
| `wp-playground` | WordPress Playground |
| `wp-project-triage` | 案件の進め方・方針判断 |
| `wp-abilities-api` | Capabilities API |
| `wordpress-router` | ルーティング |
| `wpds` | WordPress Design System |
| `adversarial-reviewer` | バグ・脆弱性の厳格レビュー |
| `security-review` | セキュリティチェック |
| `tdd-workflow` | テスト駆動開発 |
| `agent-browser` | ブラウザ自動操作・UI 確認 |
