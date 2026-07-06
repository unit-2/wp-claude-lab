load 'helpers'

run_pre_wpcli() {
  local command="$1"
  echo "{\"tool_input\":{\"command\":\"${command}\"}}" | bash "$REPO_ROOT/.claude/hooks/pre-wpcli.sh"
}

@test "wp db drop → exit 2" {
  run run_pre_wpcli "wp db drop"
  [ "$status" -eq 2 ]
  [[ "$output" == *"データベースを完全に破棄"* ]]
}

@test "wp search-replace（--dry-run あり） → exit 0" {
  run run_pre_wpcli "wp search-replace a b --dry-run"
  [ "$status" -eq 0 ]
}

@test "wp search-replace（--dry-run なし） → exit 2" {
  run run_pre_wpcli "wp search-replace a b"
  [ "$status" -eq 2 ]
  [[ "$output" == *"--dry-run なしでは実行できません"* ]]
}

@test "wp post list → exit 0" {
  run run_pre_wpcli "wp post list"
  [ "$status" -eq 0 ]
}
