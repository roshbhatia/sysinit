#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/completions.sh (begin)
# Initialize Homebrew environment
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

_evalcache atuin init zsh --disable-up-arrow
_evalcache direnv hook zsh
_evalcache gh copilot alias -- zsh

_evalcache kubectl completion zsh
_evalcache docker completion zsh
# modules/darwin/home/zsh/core/completions.sh (end)
