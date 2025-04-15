#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

function ghwhoami() {
  if command -v gh &> /dev/null; then
    username=$(gh api user --jq '.login' 2>/dev/null)
    if [[ -n "$username" ]]; then
      echo "$username"
    else
      log_warn "GitHub user not logged in"
    fi
  else
    log_error "GitHub CLI not installed"
  fi
}
