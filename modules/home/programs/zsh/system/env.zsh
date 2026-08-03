#!/usr/bin/env zsh
# shellcheck disable=all
env.print() {
  local pattern=${1:-"*"}
  env | grep -E "^$pattern=" | sort | bat --style=numbers,grid
}

# The oh-my-posh git segment runs on every prompt, and a plain `git status`
# rewrites the index through `index.lock` to cache its refresh. Every shell this
# machine spawns therefore contends for that lock, and a concurrent `git add` or
# `git commit` fails with "Unable to create index.lock: File exists". Observed all
# day while committing: the index inode changes after a plain status and does not
# with this set. Only OPTIONAL locks are disabled, so commit, add, and every
# operation that genuinely needs the lock still take it.
export GIT_OPTIONAL_LOCKS=0

export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
