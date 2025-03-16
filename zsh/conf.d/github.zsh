# GitHub username function and environment variable setup
function ghwhoami() {
  gh api user --jq '.login' 2>/dev/null || echo 'Not logged in'
}

# Update GitHub user environment variable
function update_github_user() {
  export GITHUB_USER=$(ghwhoami)
}

# Update GitHub user on shell startup
update_github_user