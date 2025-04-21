#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/paths.sh (begin)
path.print() {
  echo "$PATH" | tr ':' '\n' | bat --style=numbers,grid
}

path.add.safe() {
  local dir="$1"
  if [ -d "$dir" ]; then
    if [[ ":$PATH:" != *":$dir:"* ]]; then
      export PATH="$dir:$PATH"
      log_debug "Added $dir to PATH"
    fi
  else
    log_debug "Directory $dir does not exist, skipping PATH addition"
  fi
}

paths=(
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/bin"
  "/usr/local/opt/cython/bin"
  "/usr/sbin"
  "$HOME/.krew/bin"
  "$HOME/.local/bin"
  "$HOME/.local/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.rvm/bin"
  "$HOME/.yarn/bin"
  "$HOME/bin"
  "$HOME/go/bin"
  "$XDG_CONFIG_HOME/.cargo/bin"
  "$XDG_CONFIG_HOME/yarn/global/node_modules/.bin"
  "$XDG_CONFIG_HOME/zsh/bin"
)

for dir in "${paths[@]}"; do
  path.add.safe "$dir"
done
# modules/darwin/home/zsh/core/paths.sh (end)