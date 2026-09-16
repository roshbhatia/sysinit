#!/usr/bin/env zsh
# shellcheck disable=all

__setup_completions() {
  _evalcache @fzf@ --zsh

  compdef kubecolor=kubectl
  compdef k=kubectl

  enable-fzf-tab
}

zvm_after_init_commands+=(__setup_completions)
