#!/usr/bin/env zsh
# shellcheck disable=all

__setup_prompt() {
  _evalcache oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json"
}

zvm_after_init_commands+=(__setup_prompt)
