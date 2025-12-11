#!/usr/bin/env zsh
# shellcheck disable=all

function kubectl() {
  command kubecolor "$@"
}
compdef kubectl=kubectl

function z() {
  local dir
  dir=$(zoxide query "$@")
  pushd "$dir"
}
