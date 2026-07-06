load 'helpers'

setup() {
  setup_hooks_fixture
  # このスクリプトの探索ループは composer.json のあるディレクトリまで遡るため、
  # フィクスチャルート（$FIXTURE_DIR）に置く。
  echo '{}' > "$FIXTURE_DIR/composer.json"
}

teardown() {
  # 個別テストで作った php ファイルに対応するリトライカウンタを掃除する。
  if [[ -n "$TEST_PHP_FILE" ]]; then
    rm -f "$(lint_retry_counter_path "$TEST_PHP_FILE")"
  fi
  teardown_hooks_fixture
}

run_post_edit_format() {
  local file_path="$1"
  echo "{\"tool_input\":{\"file_path\":\"${file_path}\"}}" | bash "$FIXTURE_DIR/.claude/hooks/post-edit-format.sh"
}

@test "phpcs 違反ファイル（composerスタブが非0終了） → exit 2" {
  TEST_PHP_FILE="$FIXTURE_DIR/theme/bad.php"
  echo '<?php $x=1;' > "$TEST_PHP_FILE"
  rm -f "$(lint_retry_counter_path "$TEST_PHP_FILE")"

  export STUB_COMPOSER_EXIT=1
  run run_post_edit_format "$TEST_PHP_FILE"
  unset STUB_COMPOSER_EXIT

  [ "$status" -eq 2 ]
  [[ "$output" == *"php-lint failed (1/3)"* ]]
}

@test "クリーンなファイル（composerスタブが0終了） → exit 0" {
  TEST_PHP_FILE="$FIXTURE_DIR/theme/ok.php"
  echo '<?php' > "$TEST_PHP_FILE"
  rm -f "$(lint_retry_counter_path "$TEST_PHP_FILE")"

  export STUB_COMPOSER_EXIT=0
  run run_post_edit_format "$TEST_PHP_FILE"
  unset STUB_COMPOSER_EXIT

  [ "$status" -eq 0 ]
  [ ! -f "$(lint_retry_counter_path "$TEST_PHP_FILE")" ]
}

@test "composer 不在 → exit 0 かつ警告" {
  TEST_PHP_FILE="$FIXTURE_DIR/theme/whatever.php"
  echo '<?php' > "$TEST_PHP_FILE"

  restricted_path="$(path_without_composer)"
  run env PATH="$restricted_path" bash -c "echo '{\"tool_input\":{\"file_path\":\"${TEST_PHP_FILE}\"}}' | bash '$FIXTURE_DIR/.claude/hooks/post-edit-format.sh'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"composer が見つからない"* ]]
}

@test "対象外拡張子（.txt） → exit 0" {
  TEST_PHP_FILE=""
  local file="$FIXTURE_DIR/theme/notes.txt"
  echo "memo" > "$file"

  run run_post_edit_format "$file"

  [ "$status" -eq 0 ]
}

@test "同一ファイルへの4回目の失敗で警告に降格する（リトライガード）" {
  TEST_PHP_FILE="$FIXTURE_DIR/theme/retry.php"
  echo '<?php $x=1;' > "$TEST_PHP_FILE"
  rm -f "$(lint_retry_counter_path "$TEST_PHP_FILE")"

  export STUB_COMPOSER_EXIT=1
  run run_post_edit_format "$TEST_PHP_FILE"
  [ "$status" -eq 2 ]
  [[ "$output" == *"(1/3)"* ]]

  run run_post_edit_format "$TEST_PHP_FILE"
  [ "$status" -eq 2 ]
  [[ "$output" == *"(2/3)"* ]]

  run run_post_edit_format "$TEST_PHP_FILE"
  [ "$status" -eq 2 ]
  [[ "$output" == *"(3/3)"* ]]

  run run_post_edit_format "$TEST_PHP_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"警告のみに降格"* ]]
  unset STUB_COMPOSER_EXIT
}
