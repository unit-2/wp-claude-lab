# wp-claude-lab

**AI エージェント（Claude Code）を WordPress 開発の品質ゲートに組み込む開発基盤。**

「AI にルールを読ませる」だけでは守られない。wp-claude-lab は、規約を
**ドキュメント（rules）→ 専門知識（skills）→ 自動強制（hooks）→ 運用ゲート（git hooks / スクリプト）**
の4層に分け、機械的に判定できる違反は自動でブロックし、判断が必要なレビューだけを人間に残します。

- 🧠 **19の WordPress 専門スキル** — ブロック開発 / theme.json / REST API / パフォーマンス / セキュリティレビュー
- 🔒 **自動品質ゲート** — PHP 編集で lint 自動実行、テンプレートへの PHP 混入は保存前にブロック、
  セキュリティ関連コードは編集直後に検出して警告
- ✅ **コミットは素通りさせない**（Claude Code 経由） — phpstan + レビュー確認を通過しないと
  `git commit` が拒否される（エディタ外からの直接操作は GitHub Branch Protection の担当）

## なぜ作ったか

AI コーディングエージェントは WordPress の規約（エスケープ、nonce、prepare()、
ブロックテーマの制約）を「知って」いても、長いセッションでは忘れ、劣化します。
規約文書を増やすほどコンテキストを圧迫し、かえって守られなくなる——
この問題を「文書を増やす」以外の方法で解決するのが wp-claude-lab です。

**アプローチ: 規約を4層に分離し、それぞれ最適な強制力を持たせる**

```
┌─ rules/          規約・方針（人と AI が読む「憲法」）
├─ skills/         ドメイン知識（必要なときだけロードされる手順書・19種）
├─ .claude/hooks/  自動強制（編集・コミット時に機械判定でブロック/警告・8スクリプト）
└─ .githooks/ bin/ 運用ゲート（ブランチ保護・コミット前レビューフロー）
```

層が下に行くほど強制力が強く、上に行くほど柔軟です。
「機械的に判定できる違反はフックで止める。判断が必要なレビューは人間に残す」——
この切り分けが本リポジトリの設計原則です（詳細は「設計思想」参照）。

## 動作デモ

すべて実際にコマンドを実行して得た出力です（長い箇所は `…` で省略を明示）。

### 1. テンプレートへの PHP 混入をブロック

`templates/*.html` に `<?php` を書き込もうとすると、保存前にフックが拒否します。

```bash
echo '{"tool_input":{"file_path":"'$PWD'/themes/wp-claude-lab/templates/index.html","new_string":"<?php echo 1; ?>"}}' \
  | bash .claude/hooks/pre-edit-inject-skill.sh
```

```
=== [wp-block-themes] テンプレート編集前チェック ===
# [wp-block-themes] フック注入用ルールサマリー
…（wp-block-themes / html-coding / wp-html-accessibility の3スキルのルールサマリーが注入される）…

[ERROR] PHPコードが含まれています。ブロックテーマテンプレートにPHPは使えません。
動的コンテンツが必要な場合はダイナミックブロック（render.php）を使ってください。
```

終了コード: `2`（Claude Code の編集自体がブロックされる）

### 2. レビューを通過しないと commit できない

> 前提: 何らかの変更を `git add` して staged 済みであること。staged が空の場合は
> 「エラー: staged された変更がありません」で abort します。

```bash
bash bin/wp-review.sh themes/wp-claude-lab
```

```
=== [wp-review] コミット前チェック: themes/wp-claude-lab ===

▶ phpstan を実行中...
…
 [OK] No errors

✅ phpstan: エラーなし

▶ adversarial-reviewer チェックリスト:

□ ロジック: 条件の逆転・nullチェック漏れ・オフバイワンはないか
□ セキュリティ: エスケープ・nonce・権限チェックはすべて揃っているか
□ WordPress: prepare()なしのSQLはないか。プレフィックスは付いているか
□ 型安全: 型宣言・戻り値型が揃っているか

上記を確認しましたか？ [y/N] y

✅ レビュー確認済み。git commit を実行できます。
```

このフラグを立てないまま `git commit` を実行すると、`pre-git-commit.sh` がブロックします。

### 3. リポジトリ判定（triage）

```bash
node skills/wp-project-triage/scripts/detect_wp_project.mjs
```

```json
{
  "project": {
    "kind": ["wp-content-root", "wp-site"],
    "primary": "wp-content-root"
  },
  "signals": {
    "paths": { "repoRoot": ".../wp-claude-lab/app/public/wp-content", … },
    "hasWpContentDir": true,
    "hasPluginsDir": true,
    "hasThemesDir": true,
    "isWpContentRoot": true
  },
  …
}
```

リポジトリルート自体が wp-content であるケース（このリポジトリ自身）を正しく `wp-content-root` として
判定します。`wordpress-router` / `wp-project-triage` スキルはこの出力を起点に動きます。

## アーキテクチャ

| 層 | 実体（パス） | 発火タイミング | 強制力 |
|----|-------------|----------------|--------|
| 規約 | `rules/*.md` | セッション開始時に読み込み | 参照（AI・人間が読む） |
| 専門知識 | `skills/*/` | ファイルパスや作業内容に応じて注入 | 参照（該当時のみロード） |
| 自動強制 | `.claude/hooks/*.sh` | 編集・コミット・Bash実行のたびに実行 | ブロック／警告 |
| 運用ゲート | `.githooks/`, `bin/wp-review.sh` | `git commit` / ブランチ操作時 | ブロック |

`.claude/hooks/` の各スクリプト（8個）:

| スクリプト | 発火 | 役割 |
|-----------|------|------|
| `pre-edit-inject-skill.sh` | PreToolUse: Edit\|Write | ファイルパスに応じてスキルのキーポイントを注入し、PHP混入をブロック |
| `post-edit-format.sh` | PostToolUse: Edit\|Write | ファイルタイプに応じて prettier / php-lint を自動実行 |
| `post-php-security.sh` | PostToolUse: Edit\|Write (.php) | セキュリティキーワード検出・REST API / Interactivity API ルール注入 |
| `pre-git-commit.sh` | PreToolUse: Bash (git commit) | コミット前レビューチェックをブロックで強制 |
| `pre-wpcli.sh` | PreToolUse: Bash (wp コマンド) | WP-CLI 実行前の安全チェックリストを注入 |
| `pre-bash-safety.sh` | PreToolUse: Bash | 危険なコマンドをブロックする安全ガード |
| `file-changed-security.sh` | FileChanged: .env\|wp-config.php | 機密ファイルが変更されたときに警告 |
| `session-compact-reinject.sh` | SessionStart (compact) | コンテキスト圧縮後に WordPress 必須ルールを再注入 |

`.githooks/`（`pre-commit` / `pre-push`）はローカル用の第一防衛線で、main/master への直接操作を
`/dev/tty` 経由の対話で警告します。`/dev/tty` に依存するため CI では動作しません。正式な
ブランチ保護は GitHub の Branch Protection で行います。

## 設計思想

**(1) 機械で判定できるものはフックで強制し、判断はレビュー（人間）に残す**

テンプレートへの PHP 混入や危険な Bash コマンドは、正規表現・ファイル存在チェックで白黒がつくため
フックが自動ブロックします。一方、コードの妥当性のようにケースバイケースの判断が必要なものは、
`bin/wp-review.sh` が phpstan を実行したうえで `adversarial-reviewer` チェックリストを提示し、
**人間が `[y/N]` で確認して初めてコミット許可フラグが立つ**形にしています（自動承認にはしません）。

このフラグは「レビューゲート v2」として実装済みです。単純なオン/オフではなく、
`git diff --cached` のダイジェスト（sha256）と確認時刻をフラグに記録し、`pre-git-commit.sh` が
以下のいずれかに該当すると失効させて再レビューを求めます:

- **TTL 超過**: レビュー確認から既定3日（環境変数 `WP_REVIEW_TTL` で秒数指定して変更可）が経過した
- **staged 内容の変更**: レビュー確認後に `git add` 等で staged 内容が変わり、digest が一致しなくなった

これにより「レビューした変更」と「実際にコミットする変更」が常に一致することを保証します
（`tests/hooks/pre-git-commit.bats` の9ケースで検証済み）。

**(2) 知識は必要なときだけロードする**

`rules/` は最小限のドキュメントに留め、`skills/` はフックがファイルパスに応じて自動注入します。
19種のスキルを常時コンテキストに載せるのではなく、`.html` 編集時なら html-coding /
wp-html-accessibility、`block.json` 編集時なら wp-block-development、というように
必要なスキルだけをそのつど読み込みます。

**(3) ドキュメントと実装をドリフトさせない**

`bin/wp-review.sh` のような実行フローを正とし、`rules/git-workflow.md` はそれを参照する形にしています。
ドキュメントが実装より先に進んで嘘をつく状態（今回のREADME刷新自体もそのリスクの是正の一環）を避けます。

## クイックスタート

必須環境: PHP 8.1 以上（`composer.json` の `require.php` で強制）、
[jq](https://jqlang.org/)（`brew install jq` 等。macOS 標準非搭載）、
[Local by Flywheel](https://localwp.com/) など任意のローカル WordPress 環境、
[Composer](https://getcomposer.org/)、[Claude Code](https://docs.anthropic.com/ja/docs/claude-code/overview)。

> ⚠️ `.claude/hooks/` の8スクリプト中7本がツール入力の JSON パースに `jq` を使い、
> `jq` 不在時はフェイルオープン（警告して素通り）します。`jq` を用意しないと、
> 品質ゲートの大半が気づかれないまま無効化されるため、必ずインストールしてください。

```bash
# 1. クローンして Local の wp-content と差し替える
git clone <repository-url> wp-content && cd wp-content

# 2. PHP ツールをインストール
composer install

# 3. ローカル設定ファイルを作成（サイト URL など個人の情報を書き込む）
cp CLAUDE.local.md.example CLAUDE.local.md

# 4. Git フックを有効化（main/master への直接コミットを警告）
git config core.hooksPath .githooks

# 5. Claude Code 用のフック設定をコピーして有効化
cp .claude/settings.json.example .claude/settings.json
chmod +x .claude/hooks/*.sh
```

`.claude/` 配下の設定ファイルは役割が分かれています:

| ファイル | 役割 | Git管理 |
|---------|------|---------|
| `settings.json.example` | フック・権限設定の正本（テンプレート） | 対象（コミットする） |
| `settings.json` | 実際に使われる設定（`.example` からコピー） | 対象外（`.gitignore`） |
| `settings.local.json` | 個人のさらなるローカル上書き（権限の追加許可など） | 対象外（`.gitignore`） |

新しいテーマ・プラグインを始めるときは、`themes/` または `plugins/` に新規ディレクトリを作って
Claude Code で開発を開始するだけです。PHP を書けば `php-lint` が自動実行され、完了前に
`composer run phpstan <target>` を実行します。

## 品質ゲート一覧

| コマンド | 何をするか | いつ使うか |
|---------|-----------|-----------|
| `composer run php-lint <target>` | WordPress Coding Standards 準拠チェック（PHPCS） | 実装中・コミット前 |
| `composer run php-format <target>` | 自動修正可能な規約違反を修正（PHPCBF） | php-lint でエラーが出たとき |
| `composer run php-compatibility <target>` | PHP バージョン互換チェック | リリース前 |
| `composer run phpstan <target>` | 静的解析（型エラー・未定義変数など） | 実装完了時・コミット前 |
| `composer run phpstan:baseline` | 既存エラーをベースラインへ退避 | 既存コード導入時のみ |
| `composer run test` | PHPUnit（+ Brain Monkey）実行 | 実装完了時 |
| `composer run test:hooks` | フック本体（`.claude/hooks/*.sh`）のテスト（bats-core、未導入ならスキップ） | フック変更時 |
| `bash bin/wp-review.sh <target>` | phpstan → レビューチェックリスト → コミット許可フラグ付与を一括実行 | コミット直前（最推奨） |

## スキル一覧（19種）

**開発ドメイン（9）**

| スキル | 用途 |
|--------|------|
| `wp-block-themes` | FSE・theme.json・Site Editor |
| `wp-block-development` | ブロック開発（block.json 等） |
| `wp-plugin-development` | プラグイン開発 |
| `wp-rest-api` | REST API 開発 |
| `wp-interactivity-api` | Interactivity API |
| `wp-abilities-api` | Capabilities API |
| `wpds` | WordPress Design System |
| `html-coding` | HTML コーディング規約（汎用） |
| `wp-html-accessibility` | WordPress アクセシビリティ（WCAG AA） |

**運用・環境（4）**

| スキル | 用途 |
|--------|------|
| `wp-wpcli-and-ops` | WP-CLI 操作 |
| `wp-playground` | WordPress Playground |
| `agent-browser` | ブラウザ自動操作・UI 確認 |
| `wp-performance` | パフォーマンス改善 |

**品質・レビュー（4）**

| スキル | 用途 |
|--------|------|
| `adversarial-reviewer` | バグ・脆弱性の厳格レビュー |
| `security-review` | セキュリティチェック |
| `tdd-workflow` | テスト駆動開発 |
| `wp-phpstan` | PHPStan 静的解析 |

**基盤（2）**

| スキル | 用途 |
|--------|------|
| `wordpress-router` | 作業ドメインに応じたスキルへのルーティング |
| `wp-project-triage` | リポジトリ種別・構成の判定 |

## ディレクトリ構成

```
wp-content/
├── themes/                    ← テーマ（FSE / クラシック。twenty* はデフォルトテーマで git 管理外）
├── plugins/                   ← プラグイン（自作のみ管理対象）
├── rules/                     ← Claude 向けルール定義
│   ├── wordpress.md           ← WordPress 固有ルール
│   ├── php.md                 ← PHP コーディングスタイル
│   ├── security.md            ← セキュリティルール
│   ├── testing.md             ← テスト方針
│   └── git-workflow.md        ← コミット・PR の作法
├── skills/                    ← Claude 向けスキル（19種、カテゴリは上記参照）
├── .claude/
│   ├── hooks/                 ← 自動強制フック（8スクリプト）
│   └── settings.json.example  ← フック・権限設定の正本
├── .githooks/                 ← Git フック（main/master 保護）
├── bin/
│   └── wp-review.sh           ← コミット前チェックの一括実行スクリプト
├── tests/                     ← PHPUnit テスト（Brain Monkey）
├── config/
│   ├── phpcs/phpcs.xml.dist   ← PHPCS 設定
│   └── phpstan/               ← PHPStan 設定 + ベースライン
├── composer.json              ← PHP ツール定義
├── composer.lock              ← バージョン固定（要コミット）
├── phpunit.xml.dist           ← PHPUnit 設定
├── .editorconfig              ← エディタ共通設定
├── .gitignore                 ← vendor/ uploads/ languages/ 等の除外設定
├── AGENTS.md                  ← Claude 向け指示書（= .claude/CLAUDE.md）
├── CLAUDE.local.md.example    ← ローカル設定テンプレート
└── CLAUDE.local.md            ← 自分のローカル設定（gitignore済み）
```

## ドキュメントガイド

- `AGENTS.md` — Claude Code 向けの行動規範（開発プロトコル・スキル呼び出しタイミング）
- `rules/` — PHP・WordPress・セキュリティ・テスト・Git ワークフローの規約
- English README: `README.en.md`（準備中）
