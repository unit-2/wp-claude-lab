# bats-core 用の共通ヘルパー。
# 各 .bats から `load 'helpers'` で読み込む。
# 実リポジトリの状態に依存させないため、テストは mktemp -d の使い捨てディレクトリで完結させる。

REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"

# composer コマンドが含まれるディレクトリをすべて PATH から除外した値を返す。
# 「composer 不在」ケースの検証に使う（jq/git/md5 等の他コマンドは除外しない）。
# PATH 上に複数の composer（stub-bin のスタブ、Homebrew 版、Local.app 同梱版など）が
# 併存し得るため、最初に見つかった1つだけでなく該当するディレクトリすべてを取り除く。
path_without_composer() {
  local result_path dir
  result_path=""
  IFS=':' read -r -a dirs <<< "$PATH"
  for dir in "${dirs[@]}"; do
    [[ -x "$dir/composer" ]] && continue
    result_path="${result_path:+$result_path:}$dir"
  done
  echo "$result_path"
}

# フック本体一式（lib 含む）と bin/wp-review.sh を、独立した git リポジトリに複製する。
# コピー先で $0 の位置から相対解決される WP_CONTENT_DIR がこのフィクスチャ自身を指すようにする。
setup_hooks_fixture() {
  FIXTURE_DIR="$(mktemp -d)"
  mkdir -p "$FIXTURE_DIR/.claude/hooks/lib" "$FIXTURE_DIR/bin" "$FIXTURE_DIR/skills" "$FIXTURE_DIR/stub-bin" "$FIXTURE_DIR/theme"

  cp "$REPO_ROOT/.claude/hooks/"*.sh "$FIXTURE_DIR/.claude/hooks/"
  cp "$REPO_ROOT/.claude/hooks/lib/"*.sh "$FIXTURE_DIR/.claude/hooks/lib/"
  cp "$REPO_ROOT/bin/wp-review.sh" "$FIXTURE_DIR/bin/wp-review.sh"

  # composer スタブ。STUB_COMPOSER_EXIT で終了コードを制御する（既定 0）。
  cat > "$FIXTURE_DIR/stub-bin/composer" <<'EOF'
#!/bin/bash
echo "stub-composer: $*"
exit "${STUB_COMPOSER_EXIT:-0}"
EOF
  chmod +x "$FIXTURE_DIR/stub-bin/composer"

  ORIGINAL_PATH="$PATH"
  export PATH="$FIXTURE_DIR/stub-bin:$PATH"

  cd "$FIXTURE_DIR" || return 1
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  # 開発者のグローバル core.hooksPath（main/master への直接コミット確認など、/dev/tty 依存の
  # 対話的フック）がこの使い捨てリポジトリに継承されないよう、ローカル設定で無効化する。
  git config core.hooksPath /dev/null
  echo "placeholder" > theme/placeholder.txt
  git add theme/placeholder.txt
  git commit -q -m "chore: initial commit"
}

# このフィクスチャの review_flag_path() を、実装（lib/review-flag.sh）をそのまま source して
# 計算する。手書きで再実装すると改行の有無等で値がずれるため、必ずこの関数を使うこと。
fixture_review_flag_path() {
  (cd "$FIXTURE_DIR" && source "$FIXTURE_DIR/.claude/hooks/lib/review-flag.sh" && review_flag_path)
}

# レビューフラグ（/tmp/wp-review-ok-<hash>）とリトライカウンタ（/tmp/wp-lint-retry-<hash>）を
# フィクスチャ分だけ確実に消し、実リポジトリや他テストの /tmp を汚さないようにする。
teardown_hooks_fixture() {
  if [[ -n "$FIXTURE_DIR" && -d "$FIXTURE_DIR" ]]; then
    local flag
    flag="$(fixture_review_flag_path 2>/dev/null)"
    [[ -n "$flag" ]] && rm -f "$flag"
    rm -rf "$FIXTURE_DIR"
  fi
  [[ -n "$ORIGINAL_PATH" ]] && export PATH="$ORIGINAL_PATH"
  cd "$REPO_ROOT" || true
}

# post-edit-format.sh 用のリトライカウンタパスを計算する。
lint_retry_counter_path() {
  local file_path="$1"
  local hash
  hash=$(echo -n "$file_path" | { command -v md5 >/dev/null 2>&1 && md5 -q || md5sum | cut -d' ' -f1; })
  echo "/tmp/wp-lint-retry-${hash}"
}
