#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# sysinit.nix-shell::ignore

eval $(/opt/homebrew/bin/brew shellenv)

eval "$(atuin init zsh --disable-up-arrow)"
eval "$(kubectl completion zsh)"
eval "$(docker completion zsh)"
eval "$(direnv hook zsh)"
eval "$(gh copilot alias -- zsh)"
