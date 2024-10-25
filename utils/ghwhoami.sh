#!/usr/bin/env zsh
# shellcheck disable=all

function ghwhoami() {
    gh auth status -a | grep 'Logged in to github.com account' | awk '{print $7}'
}