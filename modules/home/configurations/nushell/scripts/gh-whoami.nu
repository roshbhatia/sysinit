def main [] {
  if (which gh | is-empty) {
    print "GitHub CLI not installed"
    return 1
  }
  let username = (gh api user --jq '.login' | str trim)
  if ($username | is-empty) {
    print "GitHub user not logged in"
    return 1
  }
  print $username
}
