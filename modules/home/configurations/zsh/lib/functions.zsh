#!/usr/bin/env zsh
# shellcheck disable=all
# User-facing shell functions

# Kubectl wrapper that uses kubecolor but preserves kubectl completions
function kubectl() {
  command kubecolor "$@"
}
compdef kubectl=kubectl

# Zoxide wrapper with pushd integration
function z() {
  local dir
  dir=$(zoxide query "$@")
  pushd "$dir"
}
