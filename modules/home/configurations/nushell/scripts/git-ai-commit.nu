def main [] {
  let conventional_commit_rules = "type(scope?): subject\n\nbody (optional)\n\nfooter (optional)\nWhere:\n- type: feat|fix|docs|style|refactor|perf|test|chore|build|ci|revert\n- scope: optional, describes the section\n- subject: short summary (max 72 chars, no period)"
  let commit_regex = '^(feat|fix|docs|style|refactor|perf|test|chore|build|ci|revert)(\([^)]+\))?: .{1,72}(\n\n[\s\S]*)?$'
  let max_tries = 3
  let valid_msg = ""
  let tries = 0
  while $tries < $max_tries {
    let msg = (opencode run "Generate a conventional commit message for my staged changes. ONLY output the commit message, DO NOT print anything else. ONLY PRINT THE COMMIT MESSAGE. ONLY PRINT THE COMMIT MESSAGE, NOTHING ELSE. IT SHOULD SATISFY THE REGEX I USE LATER. ONLY PRINT A COMMIT MESSAGE, IN ONE LINE ONLY!!!!!! Rules:\n$conventional_commit_rules" | lines | last)
    if ($msg | is-empty) {
      $tries = $tries + 1
      continue
    }
    if ($msg | match $commit_regex) {
      $valid_msg = $msg
      break
    } else {
      $tries = $tries + 1
    }
  }
  if ($valid_msg | is-empty) {
    $valid_msg = "chore: updates"
  }
  git commit -m $valid_msg
}
