#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
#         d8b888   888             888      
#         Y8P888   888             888      
#            888   888             888      
#  .d88b. 88888888888888b. 888  88888888b.  
# d88P"88b888888   888 "88b888  888888 "88b 
# 888  888888888   888  888888  888888  888 
# Y88b 888888Y88b. 888  888Y88b 888888 d88P 
#  "Y88888888 "Y888888  888 "Y8888888888P"  
#      888                                  
# Y8b d88P                                  
#  "Y88P"                                   

# GitHub username functions
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
