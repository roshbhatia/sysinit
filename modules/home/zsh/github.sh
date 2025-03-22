#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

#             d8b 888    888               888      
#             Y8P 888    888               888      
#                 888    888               888      
#   .d88b.  8888b.888888 88888b.  888  888 88888b.  
#  d88P"88b    "88b888   888 "88b 888  888 888 "88b 
#  888  888.d888888888   888  888 888  888 888  888 
#  Y88b 888888  888Y88b. 888  888 Y88b 888 888 d88P 
#   "Y88888"Y888888 "Y888888  888  "Y88888 88888P"  
#       888                                         
#  Y8b d88P                                         
#   "Y88P"                                          

# Ensure logging library is loaded
[ -f "$HOME/.config/zsh/loglib.sh" ] && source "$HOME/.config/zsh/loglib.sh"

# GitHub username functions
function ghwhoami() {
  if command -v gh &> /dev/null; then
    log_debug "Fetching GitHub username via API"
    username=$(gh api user --jq '.login' 2>/dev/null)
    if [[ -n "$username" ]]; then
      log_success "GitHub username retrieved" username="$username"
      echo "$username"
    else
      log_warn "GitHub user not logged in"
      echo 'Not logged in'
    fi
  else
    log_error "GitHub CLI not installed"
    echo 'gh not installed'
  fi
}

function update_github_user() {
  log_debug "Updating GITHUB_USER environment variable"
  export GITHUB_USER=$(ghwhoami)
  log_info "GitHub user updated" username="$GITHUB_USER"
}

function github_help() {
  echo "                                              "
  echo "   .d8888b.  d8b 888    888               888      "
  echo "  d88P  Y88b Y8P 888    888               888      "
  echo "  888    888     888    888               888      "
  echo "  888        888 888888 88888b.  888  888 88888b.  "
  echo "  888  88888 888 888    888 \"88b 888  888 888 \"88b "
  echo "  888    888 888 888    888  888 888  888 888  888 "
  echo "  Y88b  d88P 888 Y88b.  888  888 Y88b 888 888 d88P "
  echo "   \"Y8888P88 888  \"Y888 888  888  \"Y88888 88888P\"  "
  echo "                                      888          "
  echo "                                 Y8b d88P          "
  echo "                                  \"Y88P\"           "
  echo
  echo "GitHub Utility Commands:"
  echo "  ghwhoami           - Show current GitHub username"
  echo "  update_github_user - Update GITHUB_USER environment variable"
}

# Display help when called without arguments
if [[ $# -eq 0 && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  github_help
fi

# Update GitHub user on shell startup
update_github_user