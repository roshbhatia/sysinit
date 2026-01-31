#!/usr/bin/env zsh
# shellcheck disable=all

__setup_completions() {
  _evalcache fzf --zsh
  _evalcache kubectl completion zsh
  _evalcache nix-your-shell zsh
  _evalcache task --completion zsh
  _evalcache uv generate-shell-completion zsh

  compdef kubecolor=kubectl
  compdef k=kubectl

  enable-fzf-tab
}

zvm_after_init_commands+=(__setup_completions)
