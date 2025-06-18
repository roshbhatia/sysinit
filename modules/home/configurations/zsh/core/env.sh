#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/env.sh (begin)
env.print() {
  local pattern=${1:-"*"}
  env | grep -E "^$pattern=" | sort | bat --style=numbers,grid
}

export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"

if [[ -r ~/.config/github-copilot/apps.json ]]; then
  token=$(jq -r 'to_entries[] | select(.key | startswith("github.com")) | .value.oauth_token' ~/.config/github-copilot/apps.json 2>/dev/null)
  if [[ -n "$token" ]]; then
    export OPENAI_API_KEY="$token"
  else
    export OPENAI_API_KEY=""
  fi
else
  export OPENAI_API_KEY=""
fi
# modules/darwin/home/zsh/core/env.sh (end)

