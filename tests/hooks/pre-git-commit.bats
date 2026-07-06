load 'helpers'

setup() {
  setup_hooks_fixture
}

teardown() {
  teardown_hooks_fixture
}

run_pre_git_commit() {
  echo '{"tool_input":{"command":"git commit -m test"}}' | bash "$FIXTURE_DIR/.claude/hooks/pre-git-commit.sh"
}

@test "フラグなしで git commit → exit 2" {
  echo "change" >> theme/placeholder.txt
  git add theme/placeholder.txt

  run run_pre_git_commit

  [ "$status" -eq 2 ]
  [[ "$output" == *"コミット前チェック未完了"* ]]
}

@test "有効なフラグ（digest一致・TTL内）→ exit 0、フラグは残存する" {
  echo "change" >> theme/placeholder.txt
  git add theme/placeholder.txt

  export STUB_COMPOSER_EXIT=0
  run bash -c "echo y | bash '$FIXTURE_DIR/bin/wp-review.sh' theme"
  [ "$status" -eq 0 ]
  unset STUB_COMPOSER_EXIT

  run run_pre_git_commit
  [ "$status" -eq 0 ]

  [ -f "$(fixture_review_flag_path)" ]
}

@test "TTL超過 → exit 2、フラグは削除される" {
  echo "change" >> theme/placeholder.txt
  git add theme/placeholder.txt

  echo y | bash "$FIXTURE_DIR/bin/wp-review.sh" theme >/dev/null

  flag="$(fixture_review_flag_path)"
  digest="$(sed -n '1p' "$flag")"
  # TTL を過去に見せかける（確認時刻を UNIX エポック 0 にする）
  printf '%s\n%s\n' "$digest" "0" > "$flag"

  run run_pre_git_commit

  [ "$status" -eq 2 ]
  [[ "$output" == *"時間が経過"* ]]
  [ ! -f "$flag" ]
}

@test "レビュー後に staged 内容を変更 → exit 2" {
  echo "change" >> theme/placeholder.txt
  git add theme/placeholder.txt
  echo y | bash "$FIXTURE_DIR/bin/wp-review.sh" theme >/dev/null

  echo "more change" >> theme/placeholder.txt
  git add theme/placeholder.txt

  run run_pre_git_commit

  [ "$status" -eq 2 ]
  [[ "$output" == *"staged 内容が変更"* ]]
}

@test "git commit を含まないコマンド → exit 0（素通り）" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"git status\"}}' | bash '$FIXTURE_DIR/.claude/hooks/pre-git-commit.sh'"
  [ "$status" -eq 0 ]
}

@test "コミット成功後（staged空）に再コミット → digest不一致で exit 2" {
  echo "change" >> theme/placeholder.txt
  git add theme/placeholder.txt
  echo y | bash "$FIXTURE_DIR/bin/wp-review.sh" theme >/dev/null

  git commit -q -m "test: apply change"

  run run_pre_git_commit

  [ "$status" -eq 2 ]
  [[ "$output" == *"staged 内容が変更"* ]]
}

@test "wp-review.sh: staged が空なら abort（exit 1）" {
  run bash "$FIXTURE_DIR/bin/wp-review.sh" theme
  [ "$status" -eq 1 ]
  [[ "$output" == *"staged された変更がありません"* ]]
}

@test "wp-review.sh: phpstan 失敗なら abort（exit 1）" {
  echo "change" >> theme/placeholder.txt
  git add theme/placeholder.txt

  export STUB_COMPOSER_EXIT=1
  run bash -c "echo y | bash '$FIXTURE_DIR/bin/wp-review.sh' theme"
  unset STUB_COMPOSER_EXIT

  [ "$status" -eq 1 ]
  [[ "$output" == *"phpstan でエラー"* ]]
}

@test "wp-review.sh: y 以外の回答なら abort（exit 1）" {
  echo "change" >> theme/placeholder.txt
  git add theme/placeholder.txt

  run bash -c "echo n | bash '$FIXTURE_DIR/bin/wp-review.sh' theme"

  [ "$status" -eq 1 ]
  [[ "$output" == *"確認をキャンセル"* ]]
}
